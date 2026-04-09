import Foundation
import Observation
import os.log
#if canImport(StoreKit)
    import StoreKit
#endif

public enum SaneDistributionChannel: Sendable {
    case direct
    case appStore
    case setapp

    public var showsSupportSection: Bool {
        self == .direct
    }

    public var supportsInAppUpdates: Bool {
        self == .direct
    }

    public var managementLabel: String? {
        switch self {
        case .direct:
            nil
        case .appStore:
            "Managed by App Store"
        case .setapp:
            "Managed by Setapp"
        }
    }

    public var unlockExplanation: String {
        switch self {
        case .direct:
            "This only checks whether your unlock is valid. It does not upload your files, profiles, or app content."
        case .appStore:
            "This build unlocks Pro through the App Store. It does not upload your files, profiles, or app content."
        case .setapp:
            "This build unlocks through Setapp. It does not upload your files, profiles, or app content."
        }
    }

    public var purchaseManagementMessage: String {
        switch self {
        case .direct:
            "This build uses direct purchase."
        case .appStore:
            "This App Store build unlocks Pro with an in-app purchase."
        case .setapp:
            "This Setapp build manages access through Setapp."
        }
    }
}

@MainActor
public protocol LicenseSettingsServiceProtocol: AnyObject, Observable {
    var isPro: Bool { get }
    var licenseEmail: String? { get }
    var isValidating: Bool { get }
    var isPurchasing: Bool { get }
    var validationError: String? { get set }
    var purchaseError: String? { get set }
    var appStoreDisplayPrice: String? { get }
    var alternateEntryLabel: String { get }
    var accessManagementLabel: String { get }
    var alternateEntryInstruction: String { get }
    var checkoutURL: URL? { get }
    var distributionChannel: SaneDistributionChannel { get }
    var usesAppStorePurchase: Bool { get }
    var usesSetappPurchase: Bool { get }

    func checkCachedLicense()
    func preloadAppStoreProduct() async
    func purchasePro() async
    func restorePurchases() async
    func activate(key: String) async
    func deactivate()
}

/// Manages purchase status for paid SaneApps. Validates via LemonSqueezy API, caches in Keychain.
///
/// Unlike SaneBar's freemium model, this is a full gate: no purchase = no app.
/// Initialize with app-specific name and checkout URL.
///
/// ```swift
/// let licenseService = LicenseService(
///     appName: "SaneClick",
///     checkoutURL: LicenseService.directCheckoutURL(appSlug: "saneclick")
/// )
/// licenseService.checkCachedLicense()
/// ```
@MainActor @Observable
public final class LicenseService: LicenseSettingsServiceProtocol {
    public struct DirectCopy: Sendable {
        public let alternateUnlockLabel: String
        public let alternateEntryLabel: String
        public let accessManagementLabel: String
        public let alternateEntryInstruction: String

        public init(
            alternateUnlockLabel: String,
            alternateEntryLabel: String,
            accessManagementLabel: String,
            alternateEntryInstruction: String
        ) {
            self.alternateUnlockLabel = alternateUnlockLabel
            self.alternateEntryLabel = alternateEntryLabel
            self.accessManagementLabel = accessManagementLabel
            self.alternateEntryInstruction = alternateEntryInstruction
        }
    }

    public enum PurchaseBackend: Sendable {
        case direct(checkoutURL: URL)
        case appStore(productID: String)
        case setapp
    }

    // MARK: - Public State

    public private(set) var isLicensed: Bool = false
    public private(set) var licenseEmail: String?
    public private(set) var isValidating: Bool = false
    public private(set) var isPurchasing: Bool = false
    public var validationError: String?
    public var purchaseError: String?
    public private(set) var appStoreDisplayPrice: String?

    /// Freemium alias — matches SaneBar convention. Apps use `isPro` in feature guards.
    public var isPro: Bool { isLicensed }

    // MARK: - Configuration

    public let appName: String
    public let purchaseBackend: PurchaseBackend
    public let directCopy: DirectCopy?
    private nonisolated static let appStoreProductIDInfoPlistKey = "AppStoreProductID"
    private nonisolated static let sparkleFeedURLInfoPlistKey = "SUFeedURL"
    private nonisolated static let fallbackLogCategory = "License"
    private nonisolated static func ascii(_ bytes: [UInt8]) -> String {
        String(decoding: bytes, as: UTF8.self)
    }

    public var alternateUnlockLabel: String {
        directCopy?.alternateUnlockLabel ?? "Unlock Pro"
    }

    public var alternateEntryLabel: String {
        directCopy?.alternateEntryLabel ?? "Enter License Key"
    }

    public var accessManagementLabel: String {
        directCopy?.accessManagementLabel ?? "Deactivate Pro"
    }

    public var alternateEntryInstruction: String {
        directCopy?.alternateEntryInstruction ?? "Follow the instructions from your email."
    }

    public nonisolated static func directCheckoutURL(appSlug: String, ref: String? = nil) -> URL {
        var components = URLComponents()
        components.scheme = ascii([104, 116, 116, 112, 115])
        components.host = [ascii([103, 111]), ascii([115, 97, 110, 101, 97, 112, 112, 115]), ascii([99, 111, 109])].joined(separator: ".")
        components.path = "/" + [ascii([98, 117, 121]), appSlug].joined(separator: "/")
        if let ref, !ref.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            components.queryItems = [URLQueryItem(name: "ref", value: ref)]
        }
        guard let url = components.url else {
            preconditionFailure("Failed to construct direct checkout URL for \(appSlug)")
        }
        return url
    }

    public var checkoutURL: URL? {
        if case let .direct(url) = purchaseBackend {
            return url
        }
        return nil
    }

    public var distributionChannel: SaneDistributionChannel {
        switch purchaseBackend {
        case .direct:
            .direct
        case .appStore:
            .appStore
        case .setapp:
            .setapp
        }
    }

    public var usesAppStorePurchase: Bool {
        distributionChannel == .appStore
    }

    public var usesSetappPurchase: Bool {
        distributionChannel == .setapp
    }

    // MARK: - Keychain Keys

    private enum Keys {
        static let licenseKey = "license_key"
        static let licenseEmail = "license_email"
        static let lastValidation = "last_validation"
    }

    private nonisolated static func infoPlistString(_ key: String, bundle: Bundle = .main) -> String? {
        guard let rawValue = bundle.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public nonisolated static func runtimeAppStoreProductID(bundle: Bundle = .main) -> String? {
        infoPlistString(appStoreProductIDInfoPlistKey, bundle: bundle)
    }

    private nonisolated static func hasSparkleFramework(bundle: Bundle = .main) -> Bool {
        let candidatePaths = [
            bundle.privateFrameworksPath.map { "\($0)/Sparkle.framework" },
            bundle.bundleURL.appendingPathComponent("Contents/Frameworks/Sparkle.framework").path
        ].compactMap { $0 }

        return candidatePaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    public nonisolated static func isRuntimeAppStoreBuild(bundle: Bundle = .main) -> Bool {
        guard runtimeAppStoreProductID(bundle: bundle) != nil else { return false }
        if hasSparkleFramework(bundle: bundle) { return false }
        let sparkleFeedURL = infoPlistString(sparkleFeedURLInfoPlistKey, bundle: bundle)
        return sparkleFeedURL == nil
    }

    private nonisolated static func lemonSqueezyValidationURL() -> URL {
        var components = URLComponents()
        components.scheme = ascii([104, 116, 116, 112, 115])
        components.host = [
            ascii([97, 112, 105]),
            ascii([108, 101, 109, 111, 110, 115, 113, 117, 101, 101, 122, 121]),
            ascii([99, 111, 109])
        ].joined(separator: ".")
        components.path = "/" + [
            ascii([118, 49]),
            ascii([108, 105, 99, 101, 110, 115, 101, 115]),
            ascii([118, 97, 108, 105, 100, 97, 116, 101])
        ].joined(separator: "/")
        guard let url = components.url else {
            preconditionFailure("Failed to construct LemonSqueezy validation URL")
        }
        return url
    }

    public nonisolated static func inferredPurchaseBackend(
        appName: String,
        directCheckoutURL: URL,
        bundle: Bundle = .main
    ) -> PurchaseBackend {
        if isRuntimeAppStoreBuild(bundle: bundle), let productID = runtimeAppStoreProductID(bundle: bundle) {
            return .appStore(productID: productID)
        }

        if let productID = runtimeAppStoreProductID(bundle: bundle) {
            Logger(
                subsystem: bundle.bundleIdentifier ?? "com.saneapps.saneui",
                category: fallbackLogCategory
            ).notice("AppStoreProductID \(productID, privacy: .public) present for \(appName, privacy: .public), but Sparkle feed is also configured. Using direct purchase flow.")
        }

        return .direct(checkoutURL: directCheckoutURL)
    }

    /// Offline grace period in days.
    private let offlineGraceDays: TimeInterval = 30

    private let keychain: KeychainServiceProtocol
    private let logger: Logger
    #if canImport(StoreKit)
        private var appStoreProduct: Product?
    #endif

    public convenience init(
        appName: String,
        checkoutURL: URL,
        keychain: KeychainServiceProtocol? = nil,
        directCopy: DirectCopy? = nil
    ) {
        self.init(
            appName: appName,
            purchaseBackend: Self.inferredPurchaseBackend(appName: appName, directCheckoutURL: checkoutURL),
            directCopy: directCopy,
            keychain: keychain
        )
    }

    public init(
        appName: String,
        purchaseBackend: PurchaseBackend,
        directCopy: DirectCopy? = nil,
        keychain: KeychainServiceProtocol? = nil
    ) {
        self.appName = appName
        self.purchaseBackend = purchaseBackend
        self.directCopy = directCopy
        self.keychain = keychain ?? KeychainService(service: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())")
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())", category: "License")
    }

    // MARK: - Startup

    /// Check cached purchase on launch. Call from `applicationDidFinishLaunching` or app init.
    public func checkCachedLicense() {
        let environment = ProcessInfo.processInfo.environment
        let arguments = ProcessInfo.processInfo.arguments
        debugLog(
            "checkCachedLicense backend=\(String(describing: distributionChannel)) " +
                "forceFree=\(environment["SANEAPPS_FORCE_FREE_MODE"] == "1" || arguments.contains("--force-free-mode")) " +
                "forcePro=\(environment["SANEAPPS_FORCE_PRO_MODE"] == "1" || arguments.contains("--force-pro-mode"))"
        )
        // Review override: force free mode regardless of build type or stored license.
        if environment["SANEAPPS_FORCE_FREE_MODE"] == "1" || arguments.contains("--force-free-mode") {
            isLicensed = false
            licenseEmail = nil
            validationError = nil
            purchaseError = nil
            debugLog("forced free mode")
            logger.info("License forced to free mode via SANEAPPS_FORCE_FREE_MODE")
            return
        }

        #if DEBUG
            if environment["SANEAPPS_FORCE_PRO_MODE"] == "1" || arguments.contains("--force-pro-mode") {
                isLicensed = true
                licenseEmail = nil
                validationError = nil
                purchaseError = nil
                debugLog("forced pro mode")
                logger.info("License forced to pro mode via debug override")
                return
            }
        #endif

        if usesAppStorePurchase {
            Task {
                await preloadAppStoreProduct()
                await refreshAppStoreEntitlement()
            }
            return
        }

        if usesSetappPurchase {
            isLicensed = true
            licenseEmail = nil
            validationError = nil
            purchaseError = nil
            logger.info("Setapp purchase backend selected; access is managed by Setapp.")
            return
        }

        #if DEBUG
            // Debug builds: auto-grant so dev builds aren't blocked by license checks.
            // Skip when running under test host to preserve test expectations.
            // Set SANEAPPS_FORCE_LICENSE_CHECK=1 to test the gate in Debug builds.
            if !SaneRuntimeEnvironment.isTestRun(),
               ProcessInfo.processInfo.environment["SANEAPPS_FORCE_LICENSE_CHECK"] != "1" {
                isLicensed = true
                licenseEmail = nil
                logger.info("DEBUG build — auto-granted license")
                return
            }
        #endif

        guard let storedKey = try? keychain.string(forKey: Keys.licenseKey),
              !storedKey.isEmpty
        else {
            isLicensed = false
            licenseEmail = nil
            debugLog("no cached key")
            logger.info("No cached unlock credential — locked")
            return
        }

        licenseEmail = try? keychain.string(forKey: Keys.licenseEmail)
        debugLog("cached key found email=\(licenseEmail ?? "nil")")

        // Check offline grace
        if let lastDateString = try? keychain.string(forKey: Keys.lastValidation),
           let lastDate = ISO8601DateFormatter().date(from: lastDateString) {
            let daysSince = Date().timeIntervalSince(lastDate) / 86400
            if daysSince <= offlineGraceDays {
                isLicensed = true
                debugLog("offline grace hit daysSince=\(Int(daysSince))")
                logger.info("License valid (offline grace, \(Int(daysSince))d since check)")
                return
            }
        }

        // Grace expired or no date — attempt background revalidation
        isLicensed = true // Optimistic while validating
        Task {
            await revalidate(key: storedKey)
        }
    }

    private func debugLog(_ message: String) {
        guard ProcessInfo.processInfo.environment["SANEAPPS_DEBUG_LICENSE"] == "1" else { return }
        let line = "[LicenseService] \(message)\n"
        let url = URL(fileURLWithPath: "/tmp/saneapps-license-debug.log")
        let data = Data(line.utf8)
        if FileManager.default.fileExists(atPath: url.path) {
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
                return
            }
        }
        try? data.write(to: url)
    }

    public func preloadAppStoreProduct() async {
        guard case let .appStore(productID) = purchaseBackend else { return }
        #if canImport(StoreKit)
            do {
                let products = try await Product.products(for: [productID])
                appStoreProduct = products.first
                appStoreDisplayPrice = appStoreProduct?.displayPrice ?? appStoreDisplayPrice
                if appStoreProduct == nil {
                    purchaseError = "Pro purchase is not configured yet in App Store Connect."
                    logger.error("StoreKit product not found for \(productID)")
                }
            } catch {
                purchaseError = "Could not load App Store pricing right now."
                logger.error("StoreKit product fetch failed: \(error.localizedDescription)")
            }
        #else
            purchaseError = "App Store purchases are not available on this platform."
        #endif
    }

    public func purchasePro() async {
        guard case let .appStore(productID) = purchaseBackend else {
            purchaseError = distributionChannel.purchaseManagementMessage
            return
        }

        #if canImport(StoreKit)
            isPurchasing = true
            purchaseError = nil
            validationError = nil

            if appStoreProduct == nil {
                await preloadAppStoreProduct()
            }

            guard let product = appStoreProduct else {
                purchaseError = "Pro purchase is not configured yet in App Store Connect."
                isPurchasing = false
                return
            }

            do {
                let result = try await product.purchase()
                switch result {
                case let .success(verification):
                    guard case let .verified(transaction) = verification else {
                        purchaseError = "Purchase verification failed. Please try again."
                        isPurchasing = false
                        return
                    }

                    if transaction.productID != productID {
                        purchaseError = "Unexpected product received from App Store."
                        isPurchasing = false
                        return
                    }

                    await transaction.finish()
                    isLicensed = true
                    licenseEmail = nil
                    purchaseError = nil
                    validationError = nil
                    logger.info("App Store purchase completed for \(productID)")
                case .pending:
                    purchaseError = "Purchase is pending approval."
                case .userCancelled:
                    break
                @unknown default:
                    purchaseError = "Purchase was not completed."
                }
            } catch {
                purchaseError = "Purchase failed. Please try again."
                logger.error("StoreKit purchase failed: \(error.localizedDescription)")
            }

            isPurchasing = false
        #else
            purchaseError = "App Store purchases are not available on this platform."
        #endif
    }

    public func restorePurchases() async {
        guard usesAppStorePurchase else { return }
        #if canImport(StoreKit)
            isPurchasing = true
            purchaseError = nil
            do {
                try await AppStore.sync()
                await refreshAppStoreEntitlement()
                if !isLicensed {
                    purchaseError = "No prior Pro purchase was found for this Apple ID."
                }
            } catch {
                purchaseError = "Restore failed. Please try again."
                logger.error("StoreKit restore failed: \(error.localizedDescription)")
            }
            isPurchasing = false
        #else
            purchaseError = "App Store purchases are not available on this platform."
        #endif
    }

    // MARK: - Activation

    /// Validate a purchase key with LemonSqueezy and unlock the app.
    public func activate(key: String) async {
        if usesAppStorePurchase {
            validationError = "Use in-app purchase to unlock Pro in this App Store build."
            return
        }

        if usesSetappPurchase {
            validationError = distributionChannel.purchaseManagementMessage
            return
        }

        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Please enter your code."
            return
        }

        isValidating = true
        validationError = nil

        do {
            let result = try await validateWithLemonSqueezy(key: trimmed)
            if result.valid {
                try keychain.set(trimmed, forKey: Keys.licenseKey)
                if let email = result.email {
                    try keychain.set(email, forKey: Keys.licenseEmail)
                    licenseEmail = email
                }
                try keychain.set(ISO8601DateFormatter().string(from: Date()), forKey: Keys.lastValidation)
                isLicensed = true
                validationError = nil
                logger.info("License activated successfully")
                let name = appName.lowercased()
                Task.detached { await EventTracker.log("license_activated", app: name) }
            } else {
                validationError = result.error ?? "Invalid code."
                logger.info("License validation failed: \(result.error ?? "invalid")")
            }
        } catch {
            validationError = ["Could not reach", "purchase server. Check your connection and try again."].joined(separator: " ")
            logger.error("License validation error: \(error.localizedDescription)")
        }

        isValidating = false
    }

    /// Remove stored license and lock the app.
    public func deactivate() {
        if usesAppStorePurchase {
            purchaseError = "App Store purchases are managed by Apple. Use Restore Purchases if needed."
            return
        }
        if usesSetappPurchase {
            purchaseError = "This Setapp build is managed by Setapp."
            return
        }
        try? keychain.delete(Keys.licenseKey)
        try? keychain.delete(Keys.licenseEmail)
        try? keychain.delete(Keys.lastValidation)
        isLicensed = false
        licenseEmail = nil
        validationError = nil
        logger.info("License deactivated")
    }

    /// Deterministic package-scoped demo state for the catalog and previews.
    @MainActor
    package func applyDemoState(
        isLicensed: Bool,
        licenseEmail: String? = nil,
        appStoreDisplayPrice: String? = nil,
        validationError: String? = nil,
        purchaseError: String? = nil,
        isPurchasing: Bool = false,
        isValidating: Bool = false
    ) {
        self.isLicensed = isLicensed
        self.licenseEmail = licenseEmail
        self.appStoreDisplayPrice = appStoreDisplayPrice
        self.validationError = validationError
        self.purchaseError = purchaseError
        self.isPurchasing = isPurchasing
        self.isValidating = isValidating
    }

    // MARK: - Private

    private func refreshAppStoreEntitlement() async {
        guard case let .appStore(productID) = purchaseBackend else { return }
        #if canImport(StoreKit)
            var unlocked = false
            for await result in Transaction.currentEntitlements {
                guard case let .verified(transaction) = result else { continue }
                guard transaction.productID == productID else { continue }
                guard transaction.revocationDate == nil else { continue }
                unlocked = true
                break
            }
            isLicensed = unlocked
            if unlocked {
                validationError = nil
                purchaseError = nil
            }
            logger.info("App Store entitlement check: \(unlocked ? "pro" : "free")")
        #endif
    }

    private func revalidate(key: String) async {
        do {
            let result = try await validateWithLemonSqueezy(key: key)
            if result.valid {
                try? keychain.set(ISO8601DateFormatter().string(from: Date()), forKey: Keys.lastValidation)
                isLicensed = true
                logger.info("Background revalidation succeeded")
            } else {
                isLicensed = false
                logger.info("Background revalidation failed — locking app")
            }
        } catch {
            // Network error — keep licensed (grace period)
            logger.info("Background revalidation network error — maintaining license")
        }
    }

    private struct ValidationResult {
        let valid: Bool
        let email: String?
        let error: String?
    }

    static func validationFailureMessage(statusCode: Int, mimeType: String?, body: String, json: [String: Any]?) -> String {
        let serverError = ["Could not reach", "purchase server. Check your connection and try again."].joined(separator: " ")
        if statusCode >= 500 || !(mimeType ?? "").lowercased().contains("json") || body.localizedCaseInsensitiveContains("just a moment") { return serverError }
        return json?["error"] as? String ?? "Invalid code."
    }

    private func validateWithLemonSqueezy(key: String) async throws -> ValidationResult {
        let url = Self.lemonSqueezyValidationURL()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body: [String: String] = ["license_key": key]
        request.httpBody = try JSONEncoder().encode(body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            return ValidationResult(valid: false, email: nil, error: "Unexpected response")
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if http.statusCode == 200 {
            let valid = json?["valid"] as? Bool ?? false
            let meta = json?["meta"] as? [String: Any]
            let email = meta?["customer_email"] as? String
            return ValidationResult(valid: valid, email: email, error: nil)
        }
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        let error = Self.validationFailureMessage(statusCode: http.statusCode, mimeType: http.value(forHTTPHeaderField: "Content-Type"), body: responseBody, json: json)
        return ValidationResult(valid: false, email: nil, error: error)
    }
}
