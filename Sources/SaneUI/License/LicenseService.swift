import Foundation
import os.log

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
    // MARK: - Public State

    public private(set) var isLicensed: Bool = false
    public private(set) var licenseEmail: String?
    public private(set) var isValidating: Bool = false
    public var validationError: String?

    /// Freemium alias — matches SaneBar convention. Apps use `isPro` in feature guards.
    public var isPro: Bool { isLicensed }

    // MARK: - Configuration

    public let appName: String
    public let checkoutURL: URL

    // MARK: - Keychain Keys

    private enum Keys {
        static let licenseKey = "license_key"
        static let licenseEmail = "license_email"
        static let lastValidation = "last_validation"
    }

    /// Offline grace period in days.
    private let offlineGraceDays: TimeInterval = 30

    private let keychain: KeychainServiceProtocol
    private let logger: Logger

    public init(
        appName: String,
        checkoutURL: URL,
        keychain: KeychainServiceProtocol? = nil
    ) {
        self.appName = appName
        self.checkoutURL = checkoutURL
        self.keychain = keychain ?? KeychainService(service: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())")
        logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.saneapps.\(appName.lowercased())", category: "License")
    }

    // MARK: - Startup

    /// Check cached license on launch. Call from `applicationDidFinishLaunching` or app init.
    public func checkCachedLicense() {
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

    // MARK: - Activation

    /// Validate a license key with LemonSqueezy and unlock the app.
    public func activate(key: String) async {
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
        try? keychain.delete(Keys.licenseKey)
        try? keychain.delete(Keys.licenseEmail)
        try? keychain.delete(Keys.lastValidation)
        isLicensed = false
        licenseEmail = nil
        validationError = nil
        logger.info("License deactivated")
    }

    // MARK: - Private

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
