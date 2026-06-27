import Foundation
import LocalAuthentication
import Security

/// Protocol for keychain operations, injectable for testing.
public protocol KeychainServiceProtocol: Sendable {
    func bool(forKey key: String) throws -> Bool?
    func set(_ value: Bool, forKey key: String) throws
    func string(forKey key: String) throws -> String?
    func set(_ value: String, forKey key: String) throws
    func delete(_ key: String) throws
}

/// Keychain error wrapper with human-readable messages.
public struct KeychainError: LocalizedError {
    public let status: OSStatus

    public var errorDescription: String? {
        SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error (\(status))"
    }
}

/// Generic keychain service for storing strings and booleans.
///
/// Bypasses real keychain in DEBUG builds (uses UserDefaults fallback) and test environments
/// to avoid password prompts during development and CI.
public final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private let service: String
    private let accessGroup: String?
    private let isTestEnvironment: Bool
    private let isKeychainBypassed: Bool
    private let fallbackDefaults: UserDefaults

    /// - Parameter accessGroup: When non-nil, items are stored in the modern
    ///   data-protection keychain under this Team-ID-prefixed access group
    ///   (e.g. "M78L6FXD48.com.mrsane.SaneHosts"). This avoids the legacy
    ///   login-keychain ACL prompt that fires when a Developer ID app's code
    ///   signature changes between the build that wrote an item and the build
    ///   that reads it. When nil (default), behavior is unchanged and items
    ///   stay in the legacy login keychain.
    public init(
        service: String = Bundle.main.bundleIdentifier ?? "com.saneapps.app",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
        // Keep no-keychain fallback data in the app's own defaults domain.
        // Sandboxed macOS builds do not reliably persist arbitrary suite names here.
        fallbackDefaults = .standard
        isTestEnvironment = SaneRuntimeEnvironment.isTestRun()
        isKeychainBypassed = Self.shouldBypassKeychain(
            environment: ProcessInfo.processInfo.environment,
            arguments: ProcessInfo.processInfo.arguments
        )
        debugLog(
            "init service=\(service) accessGroup=\(accessGroup ?? "nil") bundle=\(Bundle.main.bundleIdentifier ?? "nil") test=\(isTestEnvironment) bypass=\(isKeychainBypassed)"
        )
    }

    static func shouldBypassKeychain(
        environment: [String: String],
        arguments: [String],
        isDebugBuild: Bool = isDebugBuild
    ) -> Bool {
        let debugBypass = isDebugBuild && environment["SANEAPPS_ENABLE_KEYCHAIN_IN_DEBUG"] != "1"
        let explicitDebugBypass = isDebugBuild && (
            environment["SANEAPPS_DISABLE_KEYCHAIN"] == "1" ||
                arguments.contains("--sane-no-keychain")
        )
        return debugBypass || explicitDebugBypass
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
            true
        #else
            false
        #endif
    }

    public func bool(forKey key: String) throws -> Bool? {
        guard !isTestEnvironment else { return nil }
        if isKeychainBypassed {
            guard let storedValue = fallbackValue(forKey: fallbackKey(key)) else { return nil }
            let value: Bool
            if let boolValue = storedValue as? Bool {
                value = boolValue
            } else if let numberValue = storedValue as? NSNumber {
                value = numberValue.boolValue
            } else {
                return nil
            }
            debugLog("read bool fallback key=\(fallbackKey(key)) value=\(value)")
            return value
        }
        var query = baseQuery(account: key)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnData] = true
        query[kSecUseAuthenticationContext] = nonInteractiveAuthenticationContext()
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data { return data.first == 1 }
        if status == errSecItemNotFound {
            if let data = migrateFromLegacyIfNeeded(account: key) { return data.first == 1 }
            return nil
        }
        throw KeychainError(status: status)
    }

    public func set(_ value: Bool, forKey key: String) throws {
        guard !isTestEnvironment else { return }
        if isKeychainBypassed {
            writeFallbackValue(value as NSNumber, forKey: fallbackKey(key))
            return
        }
        let data = Data([value ? 1 : 0])
        try upsert(data: data, forKey: key)
    }

    public func string(forKey key: String) throws -> String? {
        guard !isTestEnvironment else { return nil }
        if isKeychainBypassed {
            let value = fallbackValue(forKey: fallbackKey(key)) as? String
            debugLog("read string fallback key=\(fallbackKey(key)) value=\(value ?? "nil")")
            return value
        }
        var query = baseQuery(account: key)
        query[kSecMatchLimit] = kSecMatchLimitOne
        query[kSecReturnData] = true
        query[kSecUseAuthenticationContext] = nonInteractiveAuthenticationContext()
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        if status == errSecItemNotFound {
            if let data = migrateFromLegacyIfNeeded(account: key) {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }
        throw KeychainError(status: status)
    }

    public func set(_ value: String, forKey key: String) throws {
        guard !isTestEnvironment else { return }
        if isKeychainBypassed {
            writeFallbackValue(value as NSString, forKey: fallbackKey(key))
            return
        }
        guard let data = value.data(using: .utf8) else { return }
        try upsert(data: data, forKey: key)
    }

    public func delete(_ key: String) throws {
        guard !isTestEnvironment else { return }
        if isKeychainBypassed {
            writeFallbackValue(nil, forKey: fallbackKey(key))
            return
        }
        let query = baseQuery(account: key)
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    // MARK: - Private

    /// Builds the shared item attributes, opting the operation into the
    /// data-protection keychain + access group when one is configured.
    /// Exposed (non-private) for unit testing of the query shape.
    static func makeBaseQuery(service: String, account: String, accessGroup: String?) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        if let accessGroup {
            query[kSecUseDataProtectionKeychain] = true
            query[kSecAttrAccessGroup] = accessGroup
        }
        return query
    }

    private func baseQuery(account: String) -> [CFString: Any] {
        Self.makeBaseQuery(service: service, account: account, accessGroup: accessGroup)
    }

    /// One-time migration: when this service is configured for the
    /// data-protection keychain but an item is only present in the legacy login
    /// keychain (written by a pre-accessGroup build), copy it across so future
    /// reads are silent. Returns the recovered data if a migration happened.
    ///
    /// The legacy read intentionally allows interaction. On a machine whose
    /// legacy ACL no longer matches the current signature it may surface one
    /// final keychain prompt, which rescues the stored value; on healthy
    /// machines (or after the user chose "Always Allow") it is silent. After
    /// this runs once the value lives in the data-protection keychain and the
    /// prompt never returns. The legacy copy is intentionally left in place to
    /// avoid a delete-time ACL prompt; it simply goes dormant.
    private func migrateFromLegacyIfNeeded(account: String) -> Data? {
        guard accessGroup != nil else { return nil }
        let legacyQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(legacyQuery as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        try? upsert(data: data, forKey: account)
        debugLog("migrated key=\(account) from legacy login keychain")
        return data
    }

    private func upsert(data: Data, forKey key: String) throws {
        let query = baseQuery(account: key)
        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
            return
        }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    private func fallbackKey(_ key: String) -> String {
        "sane.no-keychain.\(service).\(key)"
    }

    private func nonInteractiveAuthenticationContext() -> LAContext {
        let context = LAContext()
        context.interactionNotAllowed = true
        return context
    }

    private func fallbackValue(forKey key: String) -> Any? {
        if let value = fallbackDefaults.object(forKey: key) {
            return value
        }
        return CFPreferencesCopyAppValue(key as CFString, service as CFString)
    }

    private func writeFallbackValue(_ value: Any?, forKey key: String) {
        if let value {
            fallbackDefaults.set(value, forKey: key)
        } else {
            fallbackDefaults.removeObject(forKey: key)
        }
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList?, service as CFString)
        CFPreferencesAppSynchronize(service as CFString)
    }

    private func debugLog(_ message: String) {
        guard ProcessInfo.processInfo.environment["SANEAPPS_DEBUG_LICENSE"] == "1" else { return }
        let line = "[KeychainService] \(message)\n"
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
}
