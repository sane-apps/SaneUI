import Foundation
import Testing
@testable import SaneUI

private final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var bools: [String: Bool] = [:]
    private var strings: [String: String] = [:]

    func bool(forKey key: String) throws -> Bool? { bools[key] }
    func set(_ value: Bool, forKey key: String) throws { bools[key] = value }
    func string(forKey key: String) throws -> String? { strings[key] }
    func set(_ value: String, forKey key: String) throws { strings[key] = value }
    func delete(_ key: String) throws {
        bools.removeValue(forKey: key)
        strings.removeValue(forKey: key)
    }
}

@Suite("Welcome Gate Flow Policy")
struct WelcomeGateFlowPolicyTests {
    @Test("Welcome gate accepts tier copy overrides")
    @MainActor
    func welcomeGateAcceptsTierCopyOverrides() {
        let service = LicenseService(
            appName: "SaneClick",
            purchaseBackend: .appStore(productID: "com.saneclick.app.pro.unlock.v3"),
            keychain: MockKeychainService()
        )

        let view = WelcomeGateView(
            appName: "SaneClick",
            appIcon: "cursorarrow.click.2",
            freeFeatures: [("star.fill", "9 core Finder actions")],
            proFeatures: [("checkmark", "Everything in Basic, plus:")],
            freeTierPrice: "Included",
            proTierPriceOverride: "One-time unlock",
            licenseService: service,
            initialPage: 6
        )

        #expect(String(describing: type(of: view)).contains("WelcomeGateView"))
    }

    @Test("Pro user always lands on Get Started")
    func proUserLabel() {
        let label = WelcomeGateFlowPolicy.finalPrimaryButtonLabel(
            isPro: true,
            selectedTier: .pro,
            usesAppStorePurchase: true
        )
        #expect(label == "Get Started")
    }

    @Test("Basic user selecting Pro on App Store shows Unlock Pro")
    func appStoreBasicSelectingProLabel() {
        let label = WelcomeGateFlowPolicy.finalPrimaryButtonLabel(
            isPro: false,
            selectedTier: .pro,
            usesAppStorePurchase: true
        )
        #expect(label == "Unlock Pro")
    }

    @Test("Basic user selecting Pro on web build shows Get Started")
    func webBasicSelectingProLabel() {
        let label = WelcomeGateFlowPolicy.finalPrimaryButtonLabel(
            isPro: false,
            selectedTier: .pro,
            usesAppStorePurchase: false
        )
        #expect(label == "Get Started")
    }

    @Test("Basic user selecting Basic shows Get Started")
    func basicTierLabel() {
        let label = WelcomeGateFlowPolicy.finalPrimaryButtonLabel(
            isPro: false,
            selectedTier: .free,
            usesAppStorePurchase: true
        )
        #expect(label == "Get Started")
    }

    @Test("Setapp selection stays on Get Started")
    func setappLabel() {
        let label = WelcomeGateFlowPolicy.finalPrimaryButtonLabel(
            isPro: false,
            selectedTier: .pro,
            channel: .setapp
        )
        #expect(label == "Get Started")
    }

    @Test("Policy action is purchase for App Store Basic+Pro selection")
    func appStoreAction() {
        let action = WelcomeGateFlowPolicy.finalPrimaryAction(
            isPro: false,
            selectedTier: .pro,
            usesAppStorePurchase: true
        )
        #expect(action == .purchasePro)
    }

    @Test("Policy action is checkout for web Basic+Pro selection")
    func webAction() {
        let action = WelcomeGateFlowPolicy.finalPrimaryAction(
            isPro: false,
            selectedTier: .pro,
            usesAppStorePurchase: false
        )
        #expect(action == .openCheckout)
    }

    @Test("Policy action is complete for Setapp Basic+Pro selection")
    func setappAction() {
        let action = WelcomeGateFlowPolicy.finalPrimaryAction(
            isPro: false,
            selectedTier: .pro,
            channel: .setapp
        )
        #expect(action == .complete)
    }
}

@Suite("License Service")
struct SaneLicenseServiceTests {
    @Test("Direct copy uses app-provided labels")
    @MainActor
    func directCopyUsesAppProvidedLabels() {
        let copy = LicenseService.DirectCopy(
            alternateUnlockLabel: "Use Activation Code",
            alternateEntryLabel: "Enter Code",
            accessManagementLabel: "Remove Unlock",
            alternateEntryInstruction: "Paste your activation code from the confirmation email."
        )
        let service = LicenseService(
            appName: "SaneClick",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "saneclick"),
            keychain: MockKeychainService(),
            directCopy: copy
        )

        #expect(service.alternateUnlockLabel == "Use Activation Code")
        #expect(service.alternateEntryLabel == "Enter Code")
        #expect(service.accessManagementLabel == "Remove Unlock")
        #expect(service.alternateEntryInstruction == "Paste your activation code from the confirmation email.")
    }

    @Test("Setapp purchase backend starts unlocked")
    @MainActor
    func setappPurchaseBackendStartsUnlocked() {
        let service = LicenseService(
            appName: "SaneClip",
            purchaseBackend: .setapp,
            keychain: MockKeychainService()
        )

        service.checkCachedLicense()

        #expect(service.isLicensed)
        #expect(service.isPro)
        #expect(service.validationError == nil)
        #expect(service.purchaseError == nil)
    }
}

@Suite("Event Tracker")
struct SaneEventTrackerTests {
    @Test("Telemetry payload includes version, channel, tier, and update target")
    func telemetryPayloadIncludesDimensions() {
        let payload = EventTracker.telemetryPayload(
            app: "saneclip",
            event: "update_available",
            tier: "pro",
            targetVersion: "2.1.33",
            targetBuild: "2133",
            appVersion: "2.1.32",
            build: "2132",
            osVersion: "15.3.1",
            platform: "macos",
            channel: "direct"
        )

        #expect(payload["app"] == "saneclip")
        #expect(payload["event"] == "update_available")
        #expect(payload["app_version"] == "2.1.32")
        #expect(payload["build"] == "2132")
        #expect(payload["os_version"] == "15.3.1")
        #expect(payload["platform"] == "macos")
        #expect(payload["channel"] == "direct")
        #expect(payload["tier"] == "pro")
        #expect(payload["target_version"] == "2.1.33")
        #expect(payload["target_build"] == "2133")
    }

    @Test("Telemetry payload infers free tier from event name")
    func telemetryPayloadInfersTier() {
        let payload = EventTracker.telemetryPayload(
            app: "saneclick",
            event: "app_launch_free",
            tier: nil,
            targetVersion: nil,
            targetBuild: nil,
            appVersion: "1.0",
            build: "100",
            osVersion: "15.3.1",
            platform: "macos",
            channel: "setapp"
        )

        #expect(payload["tier"] == "free")
        #expect(payload["channel"] == "setapp")
    }
}

@Suite("Install Location")
struct SaneInstallLocationTests {
    @Test("Treats /Applications as installed")
    func systemApplicationsPathIsInstalled() {
        #expect(SaneInstallLocation.isInApplicationsDirectory("/Applications/SaneBar.app", homeDirectory: "/Users/tester"))
    }

    @Test("Treats ~/Applications as installed")
    func userApplicationsPathIsInstalled() {
        #expect(SaneInstallLocation.isInApplicationsDirectory("/Users/tester/Applications/SaneBar.app", homeDirectory: "/Users/tester"))
    }

    @Test("Treats Downloads as not installed")
    func downloadsPathIsNotInstalled() {
        #expect(!SaneInstallLocation.isInApplicationsDirectory("/Users/tester/Downloads/SaneBar.app", homeDirectory: "/Users/tester"))
    }
}

@Suite("Sparkle Check Frequency")
struct SaneSparkleCheckFrequencyTests {
    @Test("Daily interval resolves to daily")
    func dailyIntervalResolvesToDaily() {
        #expect(SaneSparkleCheckFrequency.resolve(updateCheckInterval: 60 * 60 * 24) == .daily)
    }

    @Test("Weekly interval resolves to weekly")
    func weeklyIntervalResolvesToWeekly() {
        #expect(SaneSparkleCheckFrequency.resolve(updateCheckInterval: 60 * 60 * 24 * 7) == .weekly)
    }

    @Test("Short legacy intervals normalize to daily")
    func shortLegacyIntervalsNormalizeToDaily() {
        #expect(SaneSparkleCheckFrequency.normalizedInterval(from: 60 * 60 * 6) == SaneSparkleCheckFrequency.daily.interval)
    }
}

@Suite("Background App Defaults")
struct SaneBackgroundAppDefaultsTests {
    @Test("Background apps default to hidden Dock icon and launch at login")
    func defaultPolicyValues() {
        #expect(!SaneBackgroundAppDefaults.showDockIcon)
        #expect(SaneBackgroundAppDefaults.launchAtLogin)
    }

    @Test("Login item policy only allows installed non-DerivedData apps")
    func eligibleInstallPolicy() {
        #expect(SaneLoginItemPolicy.isEligibleInstall(bundlePath: "/Applications/SaneBar.app", homeDirectory: "/Users/tester"))
        #expect(SaneLoginItemPolicy.isEligibleInstall(bundlePath: "/Users/tester/Applications/SaneBar.app", homeDirectory: "/Users/tester"))
        #expect(!SaneLoginItemPolicy.isEligibleInstall(bundlePath: "/Users/tester/Downloads/SaneBar.app", homeDirectory: "/Users/tester"))
        #expect(!SaneLoginItemPolicy.isEligibleInstall(bundlePath: "/Users/tester/Library/Developer/Xcode/DerivedData/SaneBar.app", homeDirectory: "/Users/tester"))
    }

    @Test("Login item toggle treats requires approval as enabled")
    func toggleValueTreatsApprovalAsEnabled() {
        #expect(SaneLoginItemPolicy.toggleValue(statusProvider: { .enabled }))
        #expect(SaneLoginItemPolicy.toggleValue(statusProvider: { .requiresApproval }))
        #expect(!SaneLoginItemPolicy.toggleValue(statusProvider: { .notRegistered }))
    }

    @Test("Auto-enable registers only once on first launch")
    func autoEnableRegistersOnce() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        var registerCount = 0

        let firstRun = SaneLoginItemPolicy.enableByDefaultIfNeeded(
            isFirstLaunch: true,
            markerKey: "hasAutoEnabledLaunchAtLoginDefault",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered },
            register: { registerCount += 1 }
        )
        let secondRun = SaneLoginItemPolicy.enableByDefaultIfNeeded(
            isFirstLaunch: true,
            markerKey: "hasAutoEnabledLaunchAtLoginDefault",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered },
            register: { registerCount += 1 }
        )

        #expect(firstRun)
        #expect(!secondRun)
        #expect(registerCount == 1)
    }

    @Test("Auto-enable skips unsupported installs and missing services")
    func autoEnableSkipsUnsupportedStates() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        var registerCount = 0

        let derivedData = SaneLoginItemPolicy.enableByDefaultIfNeeded(
            isFirstLaunch: true,
            markerKey: "hasAutoEnabledLaunchAtLoginDefault",
            bundlePath: "/Users/tester/Library/Developer/Xcode/DerivedData/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered },
            register: { registerCount += 1 }
        )
        let missingService = SaneLoginItemPolicy.enableByDefaultIfNeeded(
            isFirstLaunch: true,
            markerKey: "hasAutoEnabledLaunchAtLoginDefault",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notFound },
            register: { registerCount += 1 }
        )

        #expect(!derivedData)
        #expect(!missingService)
        #expect(registerCount == 0)
    }
}

@Suite("License Validation Errors")
struct LicenseValidationErrorTests {
    @Test("Cloudflare challenge is treated as server failure")
    @MainActor
    func cloudflareChallengeMapsToServerError() {
        let message = LicenseService.validationFailureMessage(
            statusCode: 403,
            mimeType: "text/html; charset=UTF-8",
            body: "<!DOCTYPE html><title>Just a moment...</title>",
            json: nil
        )
        #expect(message == "Could not reach purchase server. Check your connection and try again.")
    }

    @Test("JSON API errors still surface as invalid key")
    @MainActor
    func jsonErrorPreserved() {
        let message = LicenseService.validationFailureMessage(
            statusCode: 404,
            mimeType: "application/json",
            body: "{\"error\":\"Invalid license key.\"}",
            json: ["error": "Invalid license key."]
        )
        #expect(message == "Invalid license key.")
    }
}

@Suite("Diagnostics Reporting")
struct DiagnosticsReportingTests {
    @Test("Markdown includes environment and settings summary")
    func markdownIncludesEnvironmentAndSettings() {
        let report = SaneDiagnosticReport(
            appName: "SaneBar",
            appVersion: "2.1.28",
            buildNumber: "2128",
            platformDescription: "macOS 26.3.1",
            deviceDescription: "Macmini9,1 (Apple Silicon)",
            recentLogs: [
                .init(timestamp: Date(timeIntervalSince1970: 1), level: "INFO", message: "launch ok")
            ],
            settingsSummary: "showDockIcon: false",
            collectedAt: Date(timeIntervalSince1970: 2)
        )

        let markdown = report.toMarkdown(userDescription: "Menu bar drifted after login")

        #expect(markdown.contains("| OS | macOS 26.3.1 |"))
        #expect(markdown.contains("| Device | Macmini9,1 (Apple Silicon) |"))
        #expect(markdown.contains("showDockIcon: false"))
        #expect(markdown.contains("Submitted via SaneBar's in-app feedback"))
    }

    @Test("Issue URL uses GitHub bug template and clipboard hint")
    @MainActor
    func issueURLUsesBugTemplate() throws {
        let report = SaneDiagnosticReport(
            appName: "SaneClip",
            appVersion: "2.2.9",
            buildNumber: "2209",
            platformDescription: "iOS 26.0",
            deviceDescription: "iPhone",
            recentLogs: [],
            settingsSummary: "historyCount: 4",
            collectedAt: Date(timeIntervalSince1970: 0)
        )

        let url = try #require(report.gitHubIssueURL(
            title: "Sync broke",
            userDescription: "Clipboard history disappeared",
            githubRepo: "SaneClip"
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(items["template"] == "bug_report.md")
        #expect(items["title"] == "Sync broke")
        #expect(items["body"]?.contains("Clipboard history disappeared") == true)
        #expect(items["body"]?.contains("Full diagnostics were copied to your clipboard.") == true)
    }
}

@Suite("Purchase Backend Inference")
struct PurchaseBackendInferenceTests {
    @Test("Bundle without AppStoreProductID stays direct")
    @MainActor
    func directBundleWithoutAppStoreProductID() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("bundle")
        let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")

        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }

        let info: [String: Any] = [
            "CFBundleIdentifier": "com.saneapps.testbundle",
            "SUFeedURL": "https://example.com/appcast.xml"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(to: infoURL)

        guard let bundle = Bundle(url: bundleURL) else {
            Issue.record("Expected temporary bundle to load")
            return
        }

        let backend = LicenseService.inferredPurchaseBackend(
            appName: "SaneHosts",
            directCheckoutURL: LicenseService.directCheckoutURL(appSlug: "sanehosts"),
            bundle: bundle
        )

        switch backend {
        case .direct(let checkoutURL):
            #expect(checkoutURL == LicenseService.directCheckoutURL(appSlug: "sanehosts"))
        case .appStore, .setapp:
            Issue.record("Direct bundle unexpectedly inferred App Store purchase backend")
        }
    }
}

@Suite("About View Policy")
struct SaneAboutViewPolicyTests {
    @Test("App Store builds hide support section")
    func appStoreBuildHidesSupportSection() {
        #expect(!SaneAboutViewPolicy.showsSupportSection(usesAppStoreBuild: true))
    }

    @Test("Direct builds keep support section")
    func directBuildKeepsSupportSection() {
        #expect(SaneAboutViewPolicy.showsSupportSection(usesAppStoreBuild: false))
    }

    @Test("Setapp builds hide support section")
    func setappBuildHidesSupportSection() {
        #expect(!SaneAboutViewPolicy.showsSupportSection(channel: .setapp))
    }
}

@Suite("Distribution Channel Policy")
struct SaneDistributionChannelTests {
    @Test("Direct channel keeps support and in-app updates")
    func directPolicy() {
        #expect(SaneDistributionChannel.direct.showsSupportSection)
        #expect(SaneDistributionChannel.direct.supportsInAppUpdates)
        #expect(SaneDistributionChannel.direct.managementLabel == nil)
    }

    @Test("Setapp channel hides support and updates")
    func setappPolicy() {
        #expect(!SaneDistributionChannel.setapp.showsSupportSection)
        #expect(!SaneDistributionChannel.setapp.supportsInAppUpdates)
        #expect(SaneDistributionChannel.setapp.managementLabel == "Managed by Setapp")
    }
}

@Suite("Shared Gradient Background")
struct SaneGradientBackgroundTests {
    @Test("Panel gradient stays calmer than standard")
    func panelGradientUsesLowerOpacity() {
        #expect(SaneGradientBackground.meshOpacity(for: .panel) < SaneGradientBackground.meshOpacity(for: .standard))
        #expect(SaneGradientBackground.meshOpacity(for: .panel) == 0.9)
        #expect(SaneGradientBackground.meshOpacity(for: .standard) == 1.0)
    }

    @Test("Panel gradient stays static even when motion is allowed")
    func panelGradientStaysStatic() {
        #expect(!SaneGradientBackground.usesAnimatedMesh(style: .panel, reduceMotion: false))
        #expect(SaneGradientBackground.usesAnimatedMesh(style: .standard, reduceMotion: false))
        #expect(!SaneGradientBackground.usesAnimatedMesh(style: .standard, reduceMotion: true))
    }
}
