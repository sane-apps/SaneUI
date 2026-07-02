import Foundation
@testable import SaneUI
import Testing

/// Minimal in-memory keychain double, kept file-local so this file stays an
/// independent unit under the SaneUITests.swift 800-line size gate.
private final class InMemoryKeychainService: KeychainServiceProtocol, @unchecked Sendable {
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

/// Pins the reachability chain that keeps LemonSqueezy checkout/validation
/// code — which still compiles into this shared module — functionally
/// unreachable for a Setapp-configured LicenseService. Setapp forbids apps
/// from surfacing purchase alternatives; this proof is what the Setapp
/// archive scanner's tolerance for the residual "lemonsqueezy"/"checkout"/
/// "License Key" strings in the compiled binary depends on. If any of these
/// regress, a Setapp customer could see (or the app could call) direct-
/// purchase surface, and the scanner tolerance must be revoked.
@Suite("License Service — Setapp purchase-surface gate")
struct SaneLicenseServiceSetappGateTests {
    @Test("Setapp backend never exposes a direct checkout URL or license-key entry")
    @MainActor
    func setappBackendNeverExposesDirectPurchaseSurface() async {
        let keychain = InMemoryKeychainService()
        let service = LicenseService(appName: "SaneClip", purchaseBackend: .setapp, keychain: keychain)

        #expect(service.usesSetappPurchase)
        #expect(!service.usesAppStorePurchase)
        #expect(service.checkoutURL == nil)
        #expect(service.distributionChannel == .setapp)

        // activate(key:) must short-circuit to the Setapp management message
        // WITHOUT ever entering the validating state — isValidating only
        // flips true after the usesSetappPurchase guard, so it staying false
        // proves the LemonSqueezy network path was never reached.
        await service.activate(key: "not-a-real-key")
        #expect(!service.isValidating)
        #expect(service.validationError == service.distributionChannel.purchaseManagementMessage)

        // checkCachedLicense() must return before it would ever call
        // revalidate(key:) (the second LemonSqueezy call site), even with a
        // stored key present — if the Setapp guard were missing, this would
        // attempt a real network call inside a unit test.
        try? keychain.set("stale-cached-key", forKey: "license_key")
        service.checkCachedLicense()
        #expect(!service.isValidating)
    }

    @Test("License entry view renders Setapp content before ever considering direct entry")
    func licenseEntryViewGatesDirectContentBehindSetappCheck() throws {
        let source = try String(
            contentsOf: URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Sources/SaneUI/License/LicenseEntryView.swift"),
            encoding: .utf8
        )

        // The direct-entry branch (which renders alternateEntryLabel /
        // checkoutURL-adjacent copy) must be reachable only via a trailing
        // else, after usesSetappPurchase and usesAppStorePurchase have both
        // already been checked — never before them.
        let setappIndex = try #require(source.range(of: "licenseService.usesSetappPurchase")?.lowerBound)
        let appStoreIndex = try #require(source.range(of: "licenseService.usesAppStorePurchase")?.lowerBound)
        let entryContentIndex = try #require(source.range(of: "} else {\n                entryContent")?.lowerBound)

        #expect(setappIndex < appStoreIndex)
        #expect(appStoreIndex < entryContentIndex)
    }

    @Test("inferredPurchaseBackend never derives .setapp — callers must pass it explicitly")
    func inferredPurchaseBackendNeverReturnsSetapp() throws {
        // inferredPurchaseBackend() is a runtime heuristic (App Store receipt
        // presence, etc.) with no reliable signal for "running under Setapp."
        // If it ever grew a `.setapp` return, an app that forgot to pass
        // purchaseBackend explicitly could silently start on the direct/
        // App Store path in a Setapp build — the exact inversion of the gate
        // this suite protects. Pin the function body to its two known return
        // sites: .appStore(...) and .direct(...), never .setapp.
        let source = try String(
            contentsOf: URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Sources/SaneUI/License/LicenseService.swift"),
            encoding: .utf8
        )
        let start = try #require(source.range(of: "static func inferredPurchaseBackend(")?.lowerBound)
        let bodyStart = try #require(source.range(of: "{", range: start ..< source.endIndex)?.upperBound)
        let bodyEnd = try #require(source.range(of: "\n    }", range: bodyStart ..< source.endIndex)?.lowerBound)
        let body = source[bodyStart ..< bodyEnd]

        #expect(body.contains(".appStore(productID:"))
        #expect(body.contains(".direct(checkoutURL:"))
        #expect(!body.contains(".setapp"))
    }
}
