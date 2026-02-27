import Foundation
import os.log
#if canImport(StoreKit)
    import StoreKit
#endif

/// Manages license status for paid SaneApps. Validates via LemonSqueezy API, caches in Keychain.
///
/// Unlike SaneBar's freemium model, this is a full gate: no license = no app.
/// Initialize with app-specific name and checkout URL.
///
/// ```swift
/// let licenseService = LicenseService(
///     appName: "SaneClick",
///     checkoutURL: URL(string: "https://go.saneapps.com/buy/saneclick")!
/// )
/// licenseService.checkCachedLicense()
/// ```
@MainActor @Observable
public final class LicenseService {
    public enum PurchaseBackend: Sendable {
        case direct(checkoutURL: URL)
        case appStore(productID: String)
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
    private static let appStoreProductIDInfoPlistKey = "AppStoreProductID"
    private static let fallbackLogCategory = "License"
    public var checkoutURL: URL? {
        if case let .direct(url) = purchaseBackend {
            return url
        }
        return nil
    }

    public var usesAppStorePurchase: Bool {
        if case .appStore = purchaseBackend {
            return true
        }
        return false
    }

    // MARK: - Keychain Keys

    private enum Keys {
        static let licenseKey = "license_key"
        static let licenseEmail = "license_email"
        static let lastValidation = "last_validation"
    }

    private static func appStoreProductIDFromBundle() -> String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: appStoreProductIDInfoPlistKey) as? String else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
        keychain: KeychainServiceProtocol? = nil
    ) {
        #if APP_STORE
            if let productID = Self.appStoreProductIDFromBundle() {
                self.init(
                    appName: appName,
                    purchaseBackend: .appStore(productID: productID),
                    keychain: keychain
                )
                return
            }
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.saneapps.saneui", category: Self.fallbackLogCategory).error(
                "APP_STORE_PRODUCT_ID not configured; using direct checkout for \(appName)."
            )
        #endif
        self.init(
            appName: appName,
            purchaseBackend: .direct(checkoutURL: checkoutURL),
            keychain: keychain
        )
    }

    public init(
        appName: String,
        purchaseBackend: PurchaseBackend,
        keychain: KeychainServiceProtocol? = nil
    ) {
        self.appName = appName
        self.purchaseBackend = purchaseBackend
        self.keychain = keychain ?? KeychainService(service: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())")
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())", category: "License")
    }

    // MARK: - Startup

    /// Check cached license on launch. Call from `applicationDidFinishLaunching` or app init.
    public func checkCachedLicense() {
        if usesAppStorePurchase {
            Task {
                await preloadAppStoreProduct()
                await refreshAppStoreEntitlement()
            }
            return
        }

        #if DEBUG
            // Debug builds: auto-grant so dev builds aren't blocked by license checks.
            // Skip when running under test host to preserve test expectations.
            // Set SANEAPPS_FORCE_LICENSE_CHECK=1 to test the gate in Debug builds.
            if NSClassFromString("XCTestCase") == nil,
               ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
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
            logger.info("No cached license key — locked")
            return
        }

        licenseEmail = try? keychain.string(forKey: Keys.licenseEmail)

        // Check offline grace
        if let lastDateString = try? keychain.string(forKey: Keys.lastValidation),
           let lastDate = ISO8601DateFormatter().date(from: lastDateString) {
            let daysSince = Date().timeIntervalSince(lastDate) / 86400
            if daysSince <= offlineGraceDays {
                isLicensed = true
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
            purchaseError = "This build uses direct license purchase."
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

    /// Validate a license key with LemonSqueezy and unlock the app.
    public func activate(key: String) async {
        if usesAppStorePurchase {
            validationError = "Use in-app purchase to unlock Pro in this App Store build."
            return
        }

        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = "Please enter a license key."
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
                validationError = result.error ?? "Invalid license key."
                logger.info("License validation failed: \(result.error ?? "invalid")")
            }
        } catch {
            validationError = "Could not reach license server. Check your connection and try again."
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
        try? keychain.delete(Keys.licenseKey)
        try? keychain.delete(Keys.licenseEmail)
        try? keychain.delete(Keys.lastValidation)
        isLicensed = false
        licenseEmail = nil
        validationError = nil
        logger.info("License deactivated")
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

    // MARK: - LemonSqueezy API

    private struct ValidationResult {
        let valid: Bool
        let email: String?
        let error: String?
    }

    private func validateWithLemonSqueezy(key: String) async throws -> ValidationResult {
        let url = URL(string: "https://api.lemonsqueezy.com/v1/licenses/validate")!
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
        } else {
            let error = json?["error"] as? String ?? "Invalid license key."
            return ValidationResult(valid: false, email: nil, error: error)
        }
    }
}
