import Foundation
import Observation
import os.log
#if canImport(StoreKit)
    import StoreKit
#endif
#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
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
    var isProTrialActive: Bool { get }
    var hasExpiredProTrial: Bool { get }
    var licenseEmail: String? { get }
    var isValidating: Bool { get }
    var isPurchasing: Bool { get }
    var validationError: String? { get set }
    var purchaseError: String? { get set }
    var appStoreDisplayPrice: String? { get }
    var displayPriceLabel: String { get }
    var alternateEntryLabel: String { get }
    var accessManagementLabel: String { get }
    var alternateEntryInstruction: String { get }
    var checkoutURL: URL? { get }
    var distributionChannel: SaneDistributionChannel { get }
    var usesAppStorePurchase: Bool { get }
    var usesSetappPurchase: Bool { get }
    var proAccessBadgeTitle: String { get }
    var proAccessDetail: String? { get }

    func checkCachedLicense()
    func preloadAppStoreProduct() async
    func purchasePro() async
    func restorePurchases() async
    func activate(key: String) async
    func deactivate()
}

/// Manages purchase status for paid SaneApps. Validates via LemonSqueezy API, caches in Keychain,
/// and can start a direct-download Pro trial before the paid gate takes over.
///
/// App Store and Setapp builds use their platform purchase state instead of direct trials.
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

    public struct ProTrialConfiguration: Sendable {
        public let durationDays: Int
        public let automaticallyStarts: Bool
        public let storageKeyPrefix: String?

        public init(durationDays: Int = 14, automaticallyStarts: Bool = true, storageKeyPrefix: String? = nil) {
            self.durationDays = max(1, durationDays)
            self.automaticallyStarts = automaticallyStarts
            self.storageKeyPrefix = storageKeyPrefix
        }
    }

    // MARK: - Public State

    public private(set) var isLicensed: Bool = false
    public private(set) var licenseEmail: String?
    public private(set) var isValidating: Bool = false
    public private(set) var isPurchasing: Bool = false
    public private(set) var hasCompletedPurchaseStateRefresh: Bool = false
    public private(set) var proTrialStartedAt: Date?
    private var proTrialLastSeenAt: Date?
    public var validationError: String?
    public var purchaseError: String?
    public private(set) var appStoreDisplayPrice: String?

    /// Freemium alias — matches SaneBar convention. Apps use `isPro` in feature guards.
    public var isPro: Bool { !isForceFreeMode && (isLicensed || isProTrialActive) }
    public var isProTrialActive: Bool {
        guard !isForceFreeMode,
              !isLicensed,
              let proTrial,
              let startedAt = proTrialStartedAt
        else { return false }
        return effectiveTrialNow() < trialEndDate(startedAt: startedAt, durationDays: proTrial.durationDays)
    }

    public var hasExpiredProTrial: Bool {
        guard !isForceFreeMode,
              !isLicensed,
              let proTrial,
              let startedAt = proTrialStartedAt
        else { return false }
        return effectiveTrialNow() >= trialEndDate(startedAt: startedAt, durationDays: proTrial.durationDays)
    }

    public var proTrialDaysRemaining: Int? {
        guard isProTrialActive,
              let proTrialStartedAt,
              let proTrial
        else { return nil }
        let remaining = trialEndDate(
            startedAt: proTrialStartedAt,
            durationDays: proTrial.durationDays
        ).timeIntervalSince(effectiveTrialNow())
        return max(1, Int(ceil(remaining / 86400)))
    }

    public var proAccessBadgeTitle: String {
        isProTrialActive ? "Pro Trial" : "Pro"
    }

    public var proAccessDetail: String? {
        if let days = proTrialDaysRemaining {
            return days == 1 ? "1 day left" : "\(days) days left"
        }
        if hasExpiredProTrial {
            return "Trial ended"
        }
        return nil
    }

    public var displayPriceLabel: String {
        appStoreDisplayPrice ?? defaultDisplayPrice
    }

    // MARK: - Configuration

    public let appName: String
    public let purchaseBackend: PurchaseBackend
    public let directCopy: DirectCopy?
    public let proTrial: ProTrialConfiguration?
    private nonisolated static let appStoreProductIDInfoPlistKey = "AppStoreProductID"
    private nonisolated static let distributionChannelInfoPlistKey = "SaneDistributionChannel"
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

    private var defaultDisplayPrice: String {
        switch appName.lowercased() {
        case "saneclick":
            "$9.99"
        case "sanesales":
            "$9.99"
        case "sanebar", "saneclip", "sanehosts":
            "$14.99"
        default:
            "$14.99"
        }
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

    public nonisolated static func runtimeDistributionChannel(bundle: Bundle = .main) -> SaneDistributionChannel? {
        guard let rawValue = infoPlistString(distributionChannelInfoPlistKey, bundle: bundle) else { return nil }
        switch rawValue.lowercased() {
        case "direct":
            return .direct
        case "appstore", "app-store", "app_store":
            return .appStore
        case "setapp":
            return .setapp
        default:
            return nil
        }
    }

    private nonisolated static func hasSparkleFramework(bundle: Bundle = .main) -> Bool {
        let candidatePaths = [
            bundle.privateFrameworksPath.map { "\($0)/Sparkle.framework" },
            bundle.bundleURL.appendingPathComponent("Contents/Frameworks/Sparkle.framework").path
        ].compactMap { $0 }

        return candidatePaths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    public nonisolated static func isRuntimeAppStoreBuild(bundle: Bundle = .main) -> Bool {
        if let explicitChannel = runtimeDistributionChannel(bundle: bundle) {
            return explicitChannel == .appStore
        }
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
    private let userDefaults: UserDefaults
    private let logger: Logger
    private var isForceFreeMode = false
    #if canImport(StoreKit)
        @ObservationIgnored private var hasConfiguredAppStoreObservation = false
        @ObservationIgnored private var appStoreTransactionUpdatesTask: Task<Void, Never>?
        @ObservationIgnored private var appStoreDidBecomeActiveTask: Task<Void, Never>?
        private var appStoreProduct: Product?
    #endif

    public convenience init(
        appName: String,
        checkoutURL: URL,
        keychain: KeychainServiceProtocol? = nil,
        directCopy: DirectCopy? = nil,
        proTrial: ProTrialConfiguration? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.init(
            appName: appName,
            purchaseBackend: Self.inferredPurchaseBackend(appName: appName, directCheckoutURL: checkoutURL),
            directCopy: directCopy,
            keychain: keychain,
            proTrial: proTrial,
            userDefaults: userDefaults
        )
    }

    public init(
        appName: String,
        purchaseBackend: PurchaseBackend,
        directCopy: DirectCopy? = nil,
        keychain: KeychainServiceProtocol? = nil,
        proTrial: ProTrialConfiguration? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.appName = appName
        self.purchaseBackend = purchaseBackend
        self.directCopy = directCopy
        self.proTrial = proTrial
        self.keychain = keychain ?? KeychainService(service: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())")
        self.userDefaults = userDefaults
        let trialStartedAtKey = Self.trialStartedAtKey(appName: appName, configuration: proTrial)
        let now = Date()
        self.proTrialStartedAt = Self.storedTrialDate(
            userDefaults: userDefaults,
            keychain: self.keychain,
            key: trialStartedAtKey,
            now: now,
            rejectsFutureDate: true
        )
        self.proTrialLastSeenAt = Self.storedTrialDate(
            userDefaults: userDefaults,
            keychain: self.keychain,
            key: Self.trialLastSeenAtKey(startedAtKey: trialStartedAtKey),
            now: now,
            rejectsFutureDate: false
        )
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())", category: "License")
    }

    deinit {
        #if canImport(StoreKit)
            appStoreTransactionUpdatesTask?.cancel()
            appStoreDidBecomeActiveTask?.cancel()
        #endif
    }

    // MARK: - Startup

    /// Check cached purchase on launch. Call from `applicationDidFinishLaunching` or app init.
    public func checkCachedLicense() {
        let environment = ProcessInfo.processInfo.environment
        let arguments = ProcessInfo.processInfo.arguments
        isForceFreeMode = false
        debugLog(
            "checkCachedLicense backend=\(String(describing: distributionChannel)) " +
                "forceFree=\(environment["SANEAPPS_FORCE_FREE_MODE"] == "1" || arguments.contains("--force-free-mode")) " +
                "forcePro=\(environment["SANEAPPS_FORCE_PRO_MODE"] == "1" || arguments.contains("--force-pro-mode"))"
        )
        // Review override: force free mode regardless of build type or stored license.
        if environment["SANEAPPS_FORCE_FREE_MODE"] == "1" || arguments.contains("--force-free-mode") {
            isForceFreeMode = true
            isLicensed = false
            licenseEmail = nil
            hasCompletedPurchaseStateRefresh = true
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
                hasCompletedPurchaseStateRefresh = true
                validationError = nil
                purchaseError = nil
                debugLog("forced pro mode")
                logger.info("License forced to pro mode via debug override")
                return
            }
        #endif

        if usesAppStorePurchase {
            hasCompletedPurchaseStateRefresh = false
            configureAppStoreObservationIfNeeded()
            Task {
                await preloadAppStoreProduct()
                await refreshAppStoreEntitlement()
            }
            return
        }

        if usesSetappPurchase {
            isLicensed = true
            licenseEmail = nil
            hasCompletedPurchaseStateRefresh = true
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
                hasCompletedPurchaseStateRefresh = true
                logger.info("DEBUG build — auto-granted license")
                return
            }
        #endif

        guard let storedKey = try? keychain.string(forKey: Keys.licenseKey),
              !storedKey.isEmpty
        else {
            isLicensed = false
            licenseEmail = nil
            hasCompletedPurchaseStateRefresh = true
            startProTrialIfNeeded()
            updateTrialLastSeenAt()
            debugLog("no cached key")
            logger.info("\(self.isProTrialActive ? "No cached unlock credential — Pro trial active" : "No cached unlock credential — locked", privacy: .public)")
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
                hasCompletedPurchaseStateRefresh = true
                debugLog("offline grace hit daysSince=\(Int(daysSince))")
                logger.info("License valid (offline grace, \(Int(daysSince))d since check)")
                return
            }
        }

        // Grace expired or no date — attempt background revalidation
        isLicensed = true // Optimistic while validating
        hasCompletedPurchaseStateRefresh = true
        Task {
            await revalidate(key: storedKey)
        }
    }

    private nonisolated static func trialStartedAtKey(appName: String, configuration: ProTrialConfiguration?) -> String? {
        guard let configuration else { return nil }
        let prefix = configuration.storageKeyPrefix ?? "saneui.\(appName.lowercased()).pro_trial"
        return "\(prefix).started_at"
    }

    private nonisolated static func trialLastSeenAtKey(startedAtKey: String?) -> String? {
        guard let startedAtKey else { return nil }
        return startedAtKey.replacingOccurrences(of: ".started_at", with: ".last_seen_at")
    }

    private nonisolated static func storedTrialDate(userDefaults: UserDefaults, keychain: KeychainServiceProtocol, key: String?, now: Date, rejectsFutureDate: Bool) -> Date? {
        guard let key else { return nil }
        if let stored = try? keychain.string(forKey: key),
           let timestamp = TimeInterval(stored),
           let date = saneTrialDate(timestamp: timestamp, now: now, rejectsFutureDate: rejectsFutureDate) {
            return date
        }
        guard userDefaults.object(forKey: key) != nil else { return nil }
        guard let date = saneTrialDate(timestamp: userDefaults.double(forKey: key), now: now, rejectsFutureDate: rejectsFutureDate) else { return nil }
        if SaneRuntimeEnvironment.isTestRun() {
            return date
        }
        do {
            try keychain.set(String(date.timeIntervalSince1970), forKey: key)
            return date
        } catch {
            return nil
        }
    }

    private nonisolated static func saneTrialDate(timestamp: TimeInterval, now: Date, rejectsFutureDate: Bool) -> Date? {
        guard timestamp.isFinite, timestamp > 0 else { return nil }
        let date = Date(timeIntervalSince1970: timestamp)
        // ponytail: tolerate clock skew; future starts reset instead of granting endless Pro.
        if rejectsFutureDate, date > now.addingTimeInterval(5 * 60) {
            return nil
        }
        return date
    }

    private func trialEndDate(startedAt: Date, durationDays: Int) -> Date {
        startedAt.addingTimeInterval(TimeInterval(durationDays) * 86400)
    }

    private func startProTrialIfNeeded(now: Date = Date()) {
        guard let proTrial,
              proTrial.automaticallyStarts,
              case .direct = purchaseBackend,
              let startedAtKey = Self.trialStartedAtKey(appName: appName, configuration: proTrial)
        else { return }

        if proTrialStartedAt == nil {
            proTrialStartedAt = now
            try? keychain.set(String(now.timeIntervalSince1970), forKey: startedAtKey)
            userDefaults.set(now.timeIntervalSince1970, forKey: startedAtKey)
            updateTrialLastSeenAt(now: now)
            let name = appName.lowercased()
            Task.detached { await EventTracker.logOnce("pro_trial_started", app: name) }
        }
    }

    private func effectiveTrialNow() -> Date {
        let now = Date()
        guard let proTrialLastSeenAt else { return now }
        return max(now, proTrialLastSeenAt)
    }

    private func updateTrialLastSeenAt(now: Date = Date()) {
        guard let key = Self.trialLastSeenAtKey(startedAtKey: Self.trialStartedAtKey(appName: appName, configuration: proTrial)) else { return }
        let effectiveNow = max(now, proTrialLastSeenAt ?? now)
        proTrialLastSeenAt = effectiveNow
        try? keychain.set(String(effectiveNow.timeIntervalSince1970), forKey: key)
        userDefaults.set(effectiveNow.timeIntervalSince1970, forKey: key)
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
        guard case let .appStore(productID) = purchaseBackend else { return }
        #if canImport(StoreKit)
            isPurchasing = true
            purchaseError = nil
            do {
                try await AppStore.sync()
                let restoredFromUnfinished = await processUnfinishedAppStoreTransactions(productID: productID)
                await refreshAppStoreEntitlement()
                if restoredFromUnfinished && !isLicensed {
                    isLicensed = true
                    purchaseError = nil
                    validationError = nil
                } else if !isLicensed {
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

        let trimmed = Self.normalizedLicenseKeyInput(key)
        guard !trimmed.isEmpty else {
            validationError = "Please enter your code."
            return
        }

        isValidating = true
        validationError = nil

        do {
            let result = try await validateWithLemonSqueezy(key: trimmed)
            if result.valid {
                guard Self.licenseProductMatchesApp(appName: appName, productName: result.productName, variantName: result.variantName) else {
                    validationError = "This code is for a different SaneApps product."
                    logger.info("License validation rejected because product did not match \(self.appName, privacy: .public)")
                    isValidating = false
                    return
                }
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

    #if canImport(StoreKit)
        private static var appDidBecomeActiveNotification: Notification.Name {
            #if canImport(UIKit)
                UIApplication.didBecomeActiveNotification
            #elseif canImport(AppKit)
                NSApplication.didBecomeActiveNotification
            #else
                Notification.Name("SaneAppsAppDidBecomeActive")
            #endif
        }

        private func configureAppStoreObservationIfNeeded() {
            guard case let .appStore(productID) = purchaseBackend else { return }
            guard !hasConfiguredAppStoreObservation else { return }

            hasConfiguredAppStoreObservation = true

            // Keep StoreKit entitlements current while the app is running, including cross-device redemptions.
            appStoreTransactionUpdatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled else { return }
                    await self?.handleAppStoreTransactionUpdate(result, expectedProductID: productID)
                }
            }

            appStoreDidBecomeActiveTask = Task { [weak self] in
                for await _ in NotificationCenter.default.notifications(named: Self.appDidBecomeActiveNotification) {
                    guard !Task.isCancelled else { return }
                    await self?.refreshAppStoreEntitlement()
                }
            }
        }

        private func handleAppStoreTransactionUpdate(
            _ result: VerificationResult<Transaction>,
            expectedProductID: String
        ) async {
            guard case let .verified(transaction) = result else {
                logger.error("Ignoring unverified App Store transaction update")
                return
            }

            guard transaction.productID == expectedProductID else { return }

            await transaction.finish()
            await refreshAppStoreEntitlement()
            logger.info("Processed App Store transaction update for \(expectedProductID, privacy: .public)")
        }

        private func processUnfinishedAppStoreTransactions(productID: String) async -> Bool {
            var unlocked = false
            for await result in Transaction.unfinished {
                guard case let .verified(transaction) = result else {
                    logger.error("Ignoring unverified unfinished App Store transaction")
                    continue
                }

                guard transaction.productID == productID else { continue }
                guard transaction.revocationDate == nil else { continue }

                isLicensed = true
                licenseEmail = nil
                purchaseError = nil
                validationError = nil
                await transaction.finish()
                unlocked = true
                logger.info("Processed unfinished App Store transaction for \(productID, privacy: .public)")
            }
            return unlocked
        }
    #else
        private func configureAppStoreObservationIfNeeded() {}
    #endif

    private func refreshAppStoreEntitlement() async {
        guard case let .appStore(productID) = purchaseBackend else { return }
        #if canImport(StoreKit)
            var unlocked = await processUnfinishedAppStoreTransactions(productID: productID)
            for await result in Transaction.currentEntitlements {
                guard case let .verified(transaction) = result else { continue }
                guard transaction.productID == productID else { continue }
                guard transaction.revocationDate == nil else { continue }
                unlocked = true
                break
            }
            if !unlocked,
               let latest = await Transaction.latest(for: productID),
               case let .verified(transaction) = latest,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                unlocked = true
            }
            isLicensed = unlocked
            hasCompletedPurchaseStateRefresh = true
            if unlocked {
                validationError = nil
                purchaseError = nil
            }
            logger.info("App Store entitlement check: \(unlocked ? "pro" : "free")")
        #else
            hasCompletedPurchaseStateRefresh = true
        #endif
    }

    private func revalidate(key: String) async {
        do {
            let result = try await validateWithLemonSqueezy(key: key)
            if result.valid, Self.licenseProductMatchesApp(appName: appName, productName: result.productName, variantName: result.variantName) {
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
        let productName: String?
        let variantName: String?
    }

    static func licenseProductMatchesApp(appName: String, productName: String?, variantName: String?) -> Bool {
        let appToken = normalizedProductToken(appName)
        guard !appToken.isEmpty else { return true }
        let productToken = productName.map(normalizedProductToken) ?? ""
        let variantToken = variantName.map(normalizedProductToken) ?? ""
        guard !productToken.isEmpty || !variantToken.isEmpty else { return false }
        let everythingBundleToken = "saneappseverythingbundle"
        return productToken.contains(appToken) ||
            variantToken.contains(appToken) ||
            productToken.contains(everythingBundleToken) ||
            variantToken.contains(everythingBundleToken)
    }

    private static func normalizedProductToken(_ value: String) -> String {
        value
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    static func normalizedLicenseKeyInput(_ value: String) -> String {
        let dashNormalized = value
            .replacingOccurrences(of: "\u{2010}", with: "-")
            .replacingOccurrences(of: "\u{2011}", with: "-")
            .replacingOccurrences(of: "\u{2012}", with: "-")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: "\u{2014}", with: "-")
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{200C}", with: "")
            .replacingOccurrences(of: "\u{200D}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")

        let pattern = /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/
        if let match = dashNormalized.firstMatch(of: pattern) {
            return String(match.output).uppercased()
        }

        return dashNormalized
            .filter { !$0.isWhitespace && !$0.isNewline }
            .uppercased()
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
            return ValidationResult(valid: false, email: nil, error: "Unexpected response", productName: nil, variantName: nil)
        }

        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        if http.statusCode == 200 {
            let valid = json?["valid"] as? Bool ?? false
            let meta = json?["meta"] as? [String: Any]
            let email = meta?["customer_email"] as? String
            let productName = meta?["product_name"] as? String
            let variantName = meta?["variant_name"] as? String
            return ValidationResult(valid: valid, email: email, error: nil, productName: productName, variantName: variantName)
        }
        let responseBody = String(data: data, encoding: .utf8) ?? ""
        let error = Self.validationFailureMessage(statusCode: http.statusCode, mimeType: http.value(forHTTPHeaderField: "Content-Type"), body: responseBody, json: json)
        return ValidationResult(valid: false, email: nil, error: error, productName: nil, variantName: nil)
    }
}
