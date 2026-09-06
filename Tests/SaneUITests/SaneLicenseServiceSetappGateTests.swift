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

    @Test("SaneApps Bundle licenses unlock each included direct Mac app")
    @MainActor
    func saneAppsBundleLicenseMatchesIncludedApps() {
        let productName = "SaneClick SaneClip SaneHosts SaneSales SaneVideo Bundle"

        for appName in ["SaneClick", "SaneClip", "SaneHosts", "SaneSales", "SaneVideo"] {
            #expect(LicenseService.licenseProductMatchesApp(
                appName: appName,
                productName: productName,
                variantName: nil
            ))
        }

        #expect(!LicenseService.licenseProductMatchesApp(
            appName: "SaneHosts",
            productName: "SaneClick",
            variantName: "Pro"
        ))
        #expect(!LicenseService.licenseProductMatchesApp(
            appName: "SaneBar",
            productName: productName,
            variantName: nil
        ))
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

#if os(macOS)
import AppKit
import Observation
import SwiftUI

/// Exercises the real SwiftUI activation observer and delayed close with no keys or network.
/// Success text still requires the separate customer-app visual acceptance check.
@Suite("License entry purchase feedback", .serialized)
@MainActor
struct LicenseEntryPurchaseFeedbackTests {
    @Test("Buying during an active trial closes after the feedback delay")
    func activeTrialPurchaseClosesAfterFeedbackDelay() async throws {
        try await assertPurchaseFeedback(trialActive: true)
    }

    @Test("Buying after a trial expires closes after the feedback delay")
    func expiredTrialPurchaseClosesAfterFeedbackDelay() async throws {
        try await assertPurchaseFeedback(trialActive: false)
    }

    @Test("Starting a trial does not trigger purchase dismissal")
    func startingTrialDoesNotTriggerPurchaseDismissal() async throws {
        let service = EntryTestLicenseService(trialActive: false)
        let host = EntryTestHost(service: service)
        defer { host.dispose() }
        #expect(await host.waitForMount())
        service.trialActive = true
        try await Task.sleep(for: .milliseconds(1800))
        #expect(service.isPro && service.isProTrialActive)
        #expect(host.closeCount == 0)
    }

    @Test("Existing Setapp access does not trigger purchase dismissal")
    func managedAccessDoesNotTriggerPurchaseDismissal() async throws {
        let service = EntryTestLicenseService(trialActive: false, channel: .setapp)
        service.paid = true
        let host = EntryTestHost(service: service)
        defer { host.dispose() }
        #expect(await host.waitForMount())
        service.purchaseError = "Fixture state refresh"
        try await Task.sleep(for: .milliseconds(1800))
        #expect(host.closeCount == 0)
    }

    private func assertPurchaseFeedback(trialActive: Bool) async throws {
        let service = EntryTestLicenseService(trialActive: trialActive)
        let host = EntryTestHost(service: service)
        defer { host.dispose() }
        #expect(await host.waitForMount())
        #expect(service.isPro == trialActive)
        // Mimic successful activation through the same protocol the real form calls.
        let activatedAt = Date()
        await service.activate(key: "fixture-only")
        #expect(service.isPro && !service.isProTrialActive)
        #expect(await host.waitForClose())
        #expect(host.closeCount == 1)
        let closedAt = try #require(host.closedAt)
        #expect(closedAt.timeIntervalSince(activatedAt) >= 1.2)
        #expect(closedAt.timeIntervalSince(activatedAt) < 3)
    }
}

@MainActor
@Observable
private final class EntryTestLicenseService: LicenseSettingsServiceProtocol {
    var paid = false
    var trialActive: Bool
    let distributionChannel: SaneDistributionChannel
    var isPro: Bool { paid || trialActive }
    var isProTrialActive: Bool { !paid && trialActive }
    var hasExpiredProTrial: Bool { !paid && !trialActive && distributionChannel == .direct }
    var licenseEmail: String? { nil }
    var isValidating: Bool { false }
    var isPurchasing: Bool { false }
    var validationError: String?
    var purchaseError: String?
    var appStoreDisplayPrice: String? { nil }
    var displayPriceLabel: String { "Fixture price" }
    var alternateEntryLabel: String { "License Key" }
    var accessManagementLabel: String { "Deactivate License" }
    var alternateEntryInstruction: String { "Enter the fixture key." }
    var checkoutURL: URL? { nil }
    var usesAppStorePurchase: Bool { distributionChannel == .appStore }
    var usesSetappPurchase: Bool { distributionChannel == .setapp }
    var proAccessBadgeTitle: String { isProTrialActive ? "Trial" : "Licensed" }
    var proAccessDetail: String? { nil }

    init(trialActive: Bool, channel: SaneDistributionChannel = .direct) {
        self.trialActive = trialActive
        distributionChannel = channel
    }

    func checkCachedLicense() {}
    func preloadAppStoreProduct() async {}
    func purchasePro() async { paid = true }
    func restorePurchases() async { paid = true }
    func activate(key: String) async { paid = true }
    func deactivate() { paid = false }
}

/// Mounts the real view; observes only its public close callback and lifecycle.
@MainActor
private final class EntryTestHost {
    let window: NSWindow
    private(set) var closeCount = 0
    private(set) var closedAt: Date?
    private var mounted = false

    init(service: EntryTestLicenseService) {
        _ = NSApplication.shared
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 448, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "SaneUI license fixture"
        window.contentView = NSHostingView(rootView: LicenseEntryView(
            licenseService: service,
            onClose: { [weak self] in
                self?.closeCount += 1
                self?.closedAt = Date()
                self?.window.close()
            }
        ).onAppear { [weak self] in self?.mounted = true })
        window.makeKeyAndOrderFront(nil)
        window.contentView?.layoutSubtreeIfNeeded()
    }

    func dispose() {
        window.contentView = nil
        window.close()
    }

    func waitForMount() async -> Bool {
        for _ in 0..<50 {
            if mounted { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }

    func waitForClose() async -> Bool {
        for _ in 0..<100 {
            if closeCount > 0 { return true }
            try? await Task.sleep(for: .milliseconds(20))
        }
        return false
    }
}
#endif
