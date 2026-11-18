import Foundation
@testable import SaneUI
import Testing

/// In-memory keychain double, file-local like the other license test files.
private final class RecheckKeychain: KeychainServiceProtocol, @unchecked Sendable {
    private var strings: [String: String] = [:]
    private var bools: [String: Bool] = [:]

    func bool(forKey key: String) throws -> Bool? {
        bools[key]
    }

    func set(_ value: Bool, forKey key: String) throws {
        bools[key] = value
    }

    func string(forKey key: String) throws -> String? {
        strings[key]
    }

    func set(_ value: String, forKey key: String) throws {
        strings[key] = value
    }

    func delete(_ key: String) throws {
        strings[key] = nil; bools[key] = nil
    }
}

/// Stands in for license.saneapps.com: answers every check with the server's
/// "not found" reply and counts how many checks arrived.
private final class RefusingLicenseServer: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var count = 0

    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    static func reset() {
        lock.lock()
        count = 0
        lock.unlock()
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.lock.lock()
        Self.count += 1
        Self.lock.unlock()
        let url = request.url ?? URL(fileURLWithPath: "/")
        let response = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        let body = Data(#"{"valid":false,"error":"license_key not found.","license_key":null,"meta":null}"#.utf8)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// SaneClick 1.3.6 test, 18 Nov 2026: a stored key the server refuses, last checked over
/// 30 days ago, made the app send about 12 checks a second. Each refusal locked the app,
/// the window swapped to the expired-trial gate, the gate's onAppear called
/// checkCachedLicense() again, which unlocked optimistically and asked again.
@Suite("License Service — one recheck per refused key", .serialized)
@MainActor
struct LicenseRecheckLoopTests {
    private func makeService() throws -> (LicenseService, RecheckKeychain) {
        // Debug builds auto-grant a licence unless this is set; `swift test` runs Debug.
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        let keychain = RecheckKeychain()
        try storeStaleKey(in: keychain)
        let defaults = try #require(UserDefaults(suiteName: "saneui-recheck-\(UUID().uuidString)"))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RefusingLicenseServer.self]
        let service = LicenseService(
            appName: "SaneClick",
            purchaseBackend: .direct(checkoutURL: URL(string: "https://example.com/buy")!),
            keychain: keychain,
            userDefaults: defaults
        )
        service.validationSession = URLSession(configuration: configuration)
        return (service, keychain)
    }

    private func storeStaleKey(in keychain: RecheckKeychain) throws {
        try keychain.set("REFUSED-KEY", forKey: "license_key")
        let sixtyDaysAgo = Date().addingTimeInterval(-60 * 86400)
        try keychain.set(ISO8601DateFormatter().string(from: sixtyDaysAgo), forKey: "last_validation")
    }

    private func waitUntil(_ condition: () -> Bool) async {
        var tries = 0
        while !condition(), tries < 300 {
            try? await Task.sleep(nanoseconds: 10_000_000)
            tries += 1
        }
    }

    @Test("A refused stored key is checked once, however often views ask again")
    func refusedKeyIsCheckedOnce() async throws {
        RefusingLicenseServer.reset()
        let (service, _) = try makeService()

        service.checkCachedLicense()
        service.checkCachedLicense() // a second view appears while the first check is running
        await waitUntil { !service.isLicensed && RefusingLicenseServer.requestCount >= 1 }
        #expect(!service.isLicensed)
        #expect(RefusingLicenseServer.requestCount == 1)

        // The lock swaps views; each onAppear asks again. None may unlock or send a request.
        for _ in 0 ..< 20 {
            service.checkCachedLicense()
            #expect(!service.isLicensed)
        }
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(!service.isLicensed)
        #expect(RefusingLicenseServer.requestCount == 1)
    }

    @Test("Deactivating clears the refusal so a newly stored key is checked again")
    func deactivateClearsRefusal() async throws {
        RefusingLicenseServer.reset()
        let (service, keychain) = try makeService()

        service.checkCachedLicense()
        await waitUntil { !service.isLicensed && RefusingLicenseServer.requestCount >= 1 }
        #expect(RefusingLicenseServer.requestCount == 1)

        service.deactivate()
        try storeStaleKey(in: keychain)
        service.checkCachedLicense()
        await waitUntil { RefusingLicenseServer.requestCount >= 2 && !service.isLicensed }
        #expect(RefusingLicenseServer.requestCount == 2)
        #expect(!service.isLicensed)
    }
}
