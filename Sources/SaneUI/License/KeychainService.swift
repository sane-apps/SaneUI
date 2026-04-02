import Foundation
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
    private let isTestEnvironment: Bool
    private let isKeychainBypassed: Bool
    private let fallbackDefaults: UserDefaults

    public init(service: String = Bundle.main.bundleIdentifier ?? "com.saneapps.app") {
        self.service = service
        // Keep no-keychain fallback data in the app's own defaults domain.
        // Sandboxed macOS builds do not reliably persist arbitrary suite names here.
        fallbackDefaults = .standard
        let debugBypass: Bool = {
            #if DEBUG
                return ProcessInfo.processInfo.environment["SANEAPPS_ENABLE_KEYCHAIN_IN_DEBUG"] != "1"
            #else
                return false
            #endif
        }()
        isTestEnvironment = SaneRuntimeEnvironment.isTestRun()
        isKeychainBypassed = debugBypass
            || ProcessInfo.processInfo.environment["SANEAPPS_DISABLE_KEYCHAIN"] == "1"
            || ProcessInfo.processInfo.arguments.contains("--sane-no-keychain")
        debugLog(
            "init service=\(service) bundle=\(Bundle.main.bundleIdentifier ?? "nil") test=\(isTestEnvironment) bypass=\(isKeychainBypassed)"
        )
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
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        guard let data = result as? Data else { return nil }
        return data.first == 1
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
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KeychainError(status: status) }
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
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
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    // MARK: - Private

    private func upsert(data: Data, forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
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
