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

/// Stands in for license.saneapps.com and counts every check it receives.
/// Keys starting with GOOD- are valid SaneClick keys; any other key gets the reply set in `mode`.
private final class StubLicenseServer: URLProtocol, @unchecked Sendable {
    enum Mode {
        case refuse // 404 JSON {"valid": false}: an explicit "not valid"
        case serverError // 503 JSON {"error": "try again"}: the server is in trouble
        case timeout // no answer at all
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var count = 0
    private nonisolated(unsafe) static var currentMode = Mode.refuse

    static var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    static func reset(mode: Mode) {
        lock.lock()
        count = 0
        currentMode = mode
        lock.unlock()
    }

    override class func canInit(with _: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    private func requestedKey() -> String {
        var data = request.httpBody ?? Data()
        if data.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            var buffer = [UInt8](repeating: 0, count: 4096)
            while stream.hasBytesAvailable {
                let read = stream.read(&buffer, maxLength: buffer.count)
                if read <= 0 {
                    break
                }
                data.append(buffer, count: read)
            }
            stream.close()
        }
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["license_key"] as? String ?? ""
    }

    private func reply(status: Int, body: String) {
        let response = HTTPURLResponse(
            url: request.url ?? URL(fileURLWithPath: "/"),
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func startLoading() {
        Self.lock.lock()
        Self.count += 1
        let mode = Self.currentMode
        Self.lock.unlock()

        if requestedKey().hasPrefix("GOOD-") {
            reply(status: 200, body: #"{"valid":true,"meta":{"product_name":"SaneClick","variant_name":"Default","customer_email":"test@example.com"}}"#)
            return
        }
        switch mode {
        case .refuse:
            reply(status: 404, body: #"{"valid":false,"error":"license_key not found.","license_key":null,"meta":null}"#)
        case .serverError:
            reply(status: 503, body: #"{"error":"Licence check is busy. Try again shortly."}"#)
        case .timeout:
            client?.urlProtocol(self, didFailWithError: URLError(.timedOut))
        }
    }

    override func stopLoading() {}
}

/// SaneClick 1.3.6 test on the Mini, 18 Nov 2026: a stored key the server refused, last checked
/// over 30 days ago, made the app send about 12 checks a second. Each refusal locked the app, the
/// window swapped to the expired-trial gate, the gate's onAppear called checkCachedLicense() again,
/// which unlocked optimistically, swapped back to the main window (whose onAppear also calls it)
/// and asked again.
@Suite("License Service — background recheck of a stored key", .serialized)
@MainActor
struct LicenseRecheckLoopTests {
    private func makeService(storedKey: String) throws -> (LicenseService, RecheckKeychain) {
        // Debug builds auto-grant a licence unless this is set; `swift test` runs Debug.
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        let keychain = RecheckKeychain()
        try storeStaleKey(storedKey, in: keychain)
        let defaults = try #require(UserDefaults(suiteName: "saneui-recheck-\(UUID().uuidString)"))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubLicenseServer.self]
        let service = LicenseService(
            appName: "SaneClick",
            purchaseBackend: .direct(checkoutURL: URL(string: "https://example.com/buy")!),
            keychain: keychain,
            userDefaults: defaults
        )
        service.validationSession = URLSession(configuration: configuration)
        return (service, keychain)
    }

    private func storeStaleKey(_ key: String, in keychain: RecheckKeychain) throws {
        try keychain.set(key, forKey: "license_key")
        let sixtyDaysAgo = Date().addingTimeInterval(-60 * 86400)
        try keychain.set(ISO8601DateFormatter().string(from: sixtyDaysAgo), forKey: "last_validation")
    }

    private func uniqueKey(_ prefix: String) -> String {
        // No dashes: activate() reduces anything shaped like a UUID to the bare UUID.
        "\(prefix)-\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
    }

    private func waitUntil(_ condition: () -> Bool) async {
        // Generous deadline: the full suite runs UI tests on the main actor at the same time.
        let deadline = Date().addingTimeInterval(15)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    /// Debug builds auto-grant a licence unless SANEAPPS_FORCE_LICENSE_CHECK is set, and other
    /// suites running in parallel set and unset it. Set it right before every call.
    private func check(_ service: LicenseService) {
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        service.checkCachedLicense()
    }

    /// Lets queued work (a finished recheck, a view swap) run before the next onAppear.
    private func settle() async {
        try? await Task.sleep(nanoseconds: 20_000_000)
    }

    @Test("The gate/main-window onAppear loop sends one request for a refused key")
    func gateAndMainWindowLoopSendsOneRequest() async throws {
        StubLicenseServer.reset(mode: .refuse)
        let (service, _) = try makeService(storedKey: uniqueKey("REFUSED"))

        // Drive it the way SaneClick's views do: whichever view is showing calls
        // checkCachedLicense() when it appears, and a state change swaps the view.
        for _ in 0 ..< 40 {
            check(service)
            await settle()
        }
        await waitUntil { !service.isLicensed } // the one answer can arrive late on a busy machine
        for _ in 0 ..< 10 {
            check(service)
            await settle()
        }

        #expect(StubLicenseServer.requestCount == 1)
        #expect(!service.isLicensed)
    }

    @Test("A cached refusal stops repeat requests, also from a second service in the same app")
    func cachedRefusalStopsRepeatRequests() async throws {
        StubLicenseServer.reset(mode: .refuse)
        let key = uniqueKey("REFUSED")
        let (service, _) = try makeService(storedKey: key)

        check(service)
        check(service) // a second view appears while the first check is running
        await waitUntil { !service.isLicensed && StubLicenseServer.requestCount >= 1 }
        #expect(StubLicenseServer.requestCount == 1)

        for _ in 0 ..< 20 {
            check(service)
            #expect(!service.isLicensed)
        }
        let (second, _) = try makeService(storedKey: key) // SaneClick makes one per Finder action
        check(second)
        #expect(!second.isLicensed)
        await settle()
        #expect(StubLicenseServer.requestCount == 1)
    }

    @Test("A server error never locks a licensed user and is not cached as a no", arguments: [
        "serverError",
        "timeout"
    ])
    func serverTroubleKeepsUserLicensed(trouble: String) async throws {
        let mode: StubLicenseServer.Mode = trouble == "timeout" ? .timeout : .serverError
        StubLicenseServer.reset(mode: mode)
        let (service, _) = try makeService(storedKey: uniqueKey("PAID"))

        check(service)
        await waitUntil { StubLicenseServer.requestCount >= 1 }
        await settle()
        #expect(service.isLicensed)

        // Views keep appearing: still licensed, and the minimum gap holds off a new request.
        for _ in 0 ..< 10 {
            check(service)
            #expect(service.isLicensed)
        }
        await settle()
        #expect(StubLicenseServer.requestCount == 1)

        // Once the gap has passed, the key is asked about again: the error was not stored as a no.
        // Keep appearing until the first check has finished and a second one starts.
        await waitUntil {
            LicenseService.forgetRecheckStartTimesForTesting()
            check(service)
            return StubLicenseServer.requestCount >= 2
        }
        await settle()
        #expect(StubLicenseServer.requestCount >= 2) // the waiting loop itself may ask more than once
        #expect(service.isLicensed)
    }

    @Test("A paying customer with an old last check is asked once and stays licensed")
    func oldValidKeyIsRecheckedAndStaysLicensed() async throws {
        StubLicenseServer.reset(mode: .refuse)
        let (service, keychain) = try makeService(storedKey: uniqueKey("GOOD"))

        for _ in 0 ..< 10 {
            check(service)
            #expect(service.isLicensed)
            await settle()
        }
        await waitUntil {
            (try? keychain.string(forKey: "last_validation")).flatMap { ISO8601DateFormatter().date(from: $0) }
                .map { Date().timeIntervalSince($0) < 60 } ?? false
        }

        #expect(StubLicenseServer.requestCount == 1)
        #expect(service.isLicensed)
        let lastCheck = try #require(try keychain.string(forKey: "last_validation"))
        let lastDate = try #require(ISO8601DateFormatter().date(from: lastCheck))
        #expect(Date().timeIntervalSince(lastDate) < 60)
    }

    @Test("Entering a key after a refusal always asks the server again")
    func enteringAKeyAfterRefusalMakesAFreshRequest() async throws {
        StubLicenseServer.reset(mode: .refuse)
        let refused = uniqueKey("REFUSED")
        let (service, _) = try makeService(storedKey: refused)

        check(service)
        await waitUntil { !service.isLicensed && StubLicenseServer.requestCount >= 1 }
        #expect(StubLicenseServer.requestCount == 1)

        // The same refused key typed in again is still checked, not answered from the cache.
        await service.activate(key: refused)
        #expect(StubLicenseServer.requestCount == 2)
        #expect(!service.isLicensed)

        // A new, valid key is checked and unlocks.
        await service.activate(key: uniqueKey("GOOD"))
        #expect(StubLicenseServer.requestCount == 3)
        #expect(service.isLicensed)
    }

    @Test("Deactivating clears the refusal so the key is checked again when stored later")
    func deactivateClearsRefusal() async throws {
        StubLicenseServer.reset(mode: .refuse)
        let key = uniqueKey("REFUSED")
        let (service, keychain) = try makeService(storedKey: key)

        check(service)
        await waitUntil { !service.isLicensed && StubLicenseServer.requestCount >= 1 }
        #expect(StubLicenseServer.requestCount == 1)

        service.deactivate()
        try storeStaleKey(key, in: keychain)
        check(service)
        await waitUntil { StubLicenseServer.requestCount >= 2 && !service.isLicensed }
        #expect(StubLicenseServer.requestCount == 2)
        #expect(!service.isLicensed)
    }
}
