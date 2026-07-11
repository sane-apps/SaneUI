import Foundation
@testable import SaneUI
import Security
import Testing
#if canImport(AppKit)
    import AppKit
#endif

private func saneUIPackageRootURL(filePath: StaticString = #filePath) -> URL {
    URL(fileURLWithPath: "\(filePath)")
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
}

private final class MockKeychainService: KeychainServiceProtocol, @unchecked Sendable {
    private var bools: [String: Bool] = [:]
    private var strings: [String: String] = [:]

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
        bools.removeValue(forKey: key)
        strings.removeValue(forKey: key)
    }
}

@Test("CompactToggle uses a labeled switch row so the whole setting is clickable")
func compactToggleUsesLabeledSwitchRow() throws {
    let source = try String(
        contentsOf: saneUIPackageRootURL()
            .appendingPathComponent("Sources/SaneUI/Components/Row.swift"),
        encoding: .utf8
    )

    #expect(source.contains("Button {"))
    #expect(source.contains("isOn.toggle()"))
    #expect(source.contains("private var switchIndicator: some View"))
    #expect(source.contains("Capsule()"))
    #expect(source.contains("Circle()"))
    #expect(source.contains(".buttonStyle(.plain)"))
    #expect(source.contains(".accessibilityLabel(label)"))
    #expect(source.contains(".accessibilityValue(isOn ? \"On\" : \"Off\")"))
    #expect(!source.contains("Toggle(\"\", isOn:"))
}

#if canImport(AppKit)
    @MainActor
    private final class MenuTarget: NSObject {
        @objc func action() {}
    }

    @Suite("Standard Menu Contract")
    @MainActor
    struct StandardMenuContractTests {
        @Test("Core utility items keep customer-critical actions in one shared order")
        func coreUtilityItemsUseSharedOrder() {
            let target = MenuTarget()
            let menu = NSMenu()
            let restartItem = SaneStandardMenu.item(
                title: "Restart Finder",
                target: target,
                action: #selector(MenuTarget.action)
            )

            SaneStandardMenu.addCoreUtilityItems(
                to: menu,
                appName: "SaneClick",
                target: target,
                settingsAction: #selector(MenuTarget.action),
                licenseAction: #selector(MenuTarget.action),
                checkForUpdatesAction: #selector(MenuTarget.action),
                configureCheckForUpdates: { $0.isEnabled = false },
                aboutAndBugReportAction: #selector(MenuTarget.action),
                extraUtilityItems: [restartItem],
                quitAction: #selector(MenuTarget.action)
            )

            let actionTitles = menu.items
                .filter { !$0.isSeparatorItem }
                .map(\.title)
            #expect(actionTitles == [
                "Settings...",
                "License...",
                "Check for Updates...",
                "About / Report a Bug...",
                "Restart Finder",
                "Quit SaneClick"
            ])
            #expect(menu.item(withTitle: "Check for Updates...")?.isEnabled == false)
            #expect(SaneStandardMenu.coreUtilityOrder == [
                "Settings...",
                "License...",
                "Check for Updates...",
                "About / Report a Bug...",
                "What's New..."
            ])
        }

        @Test("Shared update menu configurator disables ineligible direct updates")
        func updateMenuConfiguratorUsesSharedAvailabilityState() {
            let target = MenuTarget()
            let item = SaneStandardMenu.checkForUpdatesItem(
                target: target,
                action: #selector(MenuTarget.action)
            )

            SaneStandardMenu.configureUpdateItem(
                item,
                isAvailable: false,
                unavailableStatus: "Updates are available after the app is opened from your Applications folder."
            )

            #expect(!item.isEnabled)
            #expect(item.toolTip == "Updates are available after the app is opened from your Applications folder.")
        }
    }
#endif

@Suite("Runtime Environment Policy")
struct RuntimeEnvironmentPolicyTests {
    @Test("Normal app launch is not treated as a test run")
    func normalAppLaunch() {
        let result = SaneRuntimeEnvironment.isTestRun(
            environment: [:],
            processName: "SaneClip",
            bundleIdentifier: "com.saneclip.app",
            bundlePath: "/Applications/SaneClip.app"
        )

        #expect(result == false)
    }

    @Test("XCTest env vars mark a test run")
    func xctestEnvironment() {
        let result = SaneRuntimeEnvironment.isTestRun(
            environment: ["XCTestConfigurationFilePath": "/tmp/test.xctestconfiguration"],
            processName: "SaneClip",
            bundleIdentifier: "com.saneclip.app",
            bundlePath: "/Applications/SaneClip.app"
        )

        #expect(result == true)
    }

    @Test("xctest process marks a test run")
    func xctestProcess() {
        let result = SaneRuntimeEnvironment.isTestRun(
            environment: [:],
            processName: "xctest",
            bundleIdentifier: "com.saneclip.appTests",
            bundlePath: "/tmp/SaneClipTests.xctest"
        )

        #expect(result == true)
    }

    @Test("No-keychain fallback stays in the app defaults domain")
    func noKeychainFallbackUsesStandardDefaults() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/KeychainService.swift"),
            encoding: .utf8
        )

        #expect(source.contains("fallbackDefaults = .standard"))
    }

    @Test("Debug keychain bypass has explicit real-keychain opt-in")
    func debugKeychainBypassPolicyCanExerciseRealKeychain() {
        #expect(KeychainService.shouldBypassKeychain(environment: [:], arguments: [], isDebugBuild: true))
        #expect(!KeychainService.shouldBypassKeychain(
            environment: ["SANEAPPS_ENABLE_KEYCHAIN_IN_DEBUG": "1"],
            arguments: [],
            isDebugBuild: true
        ))
        #expect(KeychainService.shouldBypassKeychain(
            environment: [
                "SANEAPPS_ENABLE_KEYCHAIN_IN_DEBUG": "1",
                "SANEAPPS_DISABLE_KEYCHAIN": "1"
            ],
            arguments: [],
            isDebugBuild: true
        ))
        #expect(!KeychainService.shouldBypassKeychain(environment: [:], arguments: [], isDebugBuild: false))
        #expect(KeychainService.shouldBypassKeychain(
            environment: [:],
            arguments: ["SaneApp", "--sane-no-keychain"],
            isDebugBuild: false
        ))
        #expect(KeychainService.shouldBypassKeychain(
            environment: ["SANEAPPS_DISABLE_KEYCHAIN": "1"],
            arguments: [],
            isDebugBuild: false
        ))
    }

    @Test("Access group opts items into the data-protection keychain; nil keeps legacy behavior")
    func accessGroupSelectsDataProtectionKeychain() {
        let legacy = KeychainService.makeBaseQuery(
            service: "com.mrsane.SaneHosts",
            account: "license_key",
            accessGroup: nil
        )
        #expect(legacy[kSecAttrService] as? String == "com.mrsane.SaneHosts")
        #expect(legacy[kSecAttrAccount] as? String == "license_key")
        #expect(legacy[kSecUseDataProtectionKeychain] == nil)
        #expect(legacy[kSecAttrAccessGroup] == nil)

        let modern = KeychainService.makeBaseQuery(
            service: "com.mrsane.SaneHosts",
            account: "license_key",
            accessGroup: "M78L6FXD48.com.mrsane.SaneHosts"
        )
        #expect(modern[kSecAttrService] as? String == "com.mrsane.SaneHosts")
        #expect(modern[kSecUseDataProtectionKeychain] as? Bool == true)
        #expect(modern[kSecAttrAccessGroup] as? String == "M78L6FXD48.com.mrsane.SaneHosts")
    }
}

@Suite("Settings Localization")
struct SettingsLocalizationTests {
    private enum DemoSettingsTab: String, SaneSettingsTab {
        case general = "General"

        var icon: String {
            "gearshape"
        }

        var iconColor: Color {
            .white
        }
    }

    @Test("Settings tabs default to their raw title")
    func defaultTabTitleUsesRawValue() {
        #expect(DemoSettingsTab.general.title == "General")
    }

    @Test("Supported language codes drop Base and duplicates")
    func supportedLanguageCodesDropBaseAndDuplicates() {
        let codes = SaneAppLanguageSupport.supportedLanguageCodes(
            localizations: ["Base", "en", "ja", "ja-JP", "de"]
        )

        #expect(codes == ["en", "ja", "de"])
    }

    @Test("Current language prefers the first supported preferred language")
    func selectedLanguagePrefersSupportedPreferredLanguage() {
        let code = SaneAppLanguageSupport.selectedLanguageCode(
            supportedLanguageCodes: ["en", "ja", "de"],
            preferredLanguageCodes: ["fr-CA", "ja-JP", "de-DE"],
            developmentLocalization: "en"
        )

        #expect(code == "ja")
    }

    @Test("Current language falls back to development localization")
    func selectedLanguageFallsBackToDevelopmentLocalization() {
        let code = SaneAppLanguageSupport.selectedLanguageCode(
            supportedLanguageCodes: ["en", "ja"],
            preferredLanguageCodes: ["fr-CA"],
            developmentLocalization: "en"
        )

        #expect(code == "en")
    }
}

@Suite("Readable Help Standard")
struct ReadableHelpStandardTests {
    @Test("SaneUI exposes native hover help with matching accessibility hint")
    func saneHelpUsesAppleNativeHelp() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/Components/SaneHelp.swift"),
            encoding: .utf8
        )

        #expect(source.contains("public struct SaneHelpModifier"))
        #expect(source.contains(".help(text)"))
        #expect(source.contains(".accessibilityHint(text)"))
        #expect(!source.contains("overlay(alignment:"))
        #expect(!source.contains("onHover"))
    }

    @Test("SaneUI Catalog documents visible inline help for important explanations")
    func catalogShowsInlineHelpPattern() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUICatalog/SaneUICatalogApp.swift"),
            encoding: .utf8
        )

        #expect(source.contains(".saneHelp("))
        #expect(source.contains("SaneInlineHelp("))
    }

    @Test("Shared action buttons keep compact settings labels visible")
    func actionButtonStylePreventsClippedLabels() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/Components/Badge.swift"),
            encoding: .utf8
        )

        #expect(source.contains("public struct SaneActionButtonStyle"))
        #expect(source.contains(".lineLimit(1)"))
        #expect(source.contains(".minimumScaleFactor(0.82)"))
        #expect(source.contains(".fixedSize(horizontal: false, vertical: true)"))
    }
}

#if canImport(AppKit)
    @Suite("Permission Guidance")
    struct PermissionGuidanceTests {
        @Test("System Settings destinations use Apple preference URLs")
        func systemSettingsDestinationsUsePreferenceURLs() {
            #expect(SaneSystemSettingsDestination.automation.url.absoluteString.contains("Privacy_Automation"))
            #expect(SaneSystemSettingsDestination.screenRecording.url.absoluteString.contains("Privacy_ScreenCapture"))
            #expect(SaneSystemSettingsDestination.microphone.url.absoluteString.contains("Privacy_Microphone"))
        }

        @Test("Permission guidance uses shared styling and hover help")
        func permissionGuidanceUsesSharedStyling() throws {
            let source = try String(
                contentsOf: saneUIPackageRootURL()
                    .appendingPathComponent("Sources/SaneUI/Components/SanePermissionGuidanceView.swift"),
                encoding: .utf8
            )

            #expect(source.contains("SaneActionButtonStyle"))
            #expect(source.contains(".saneHelp("))
            #expect(!source.contains(".foregroundStyle(.secondary)"))
            #expect(!source.contains(".buttonStyle(.bordered"))
            #expect(!source.contains("minWidth: 520"))
        }
    }

    @Suite("App Storage")
    struct AppStorageTests {
        @Test("Shared storage helper keeps app internals out of Documents")
        func sharedStorageHelperAvoidsDocuments() throws {
            let source = try String(
                contentsOf: saneUIPackageRootURL()
                    .appendingPathComponent("Sources/SaneUI/Components/SaneAppStorage.swift"),
                encoding: .utf8
            )

            #expect(source.contains(".applicationSupportDirectory"))
            #expect(source.contains(".cachesDirectory"))
            #expect(source.contains(".libraryDirectory"))
            #expect(!source.contains(".documentDirectory"))
        }
    }

    @Suite("Settings Container")
    struct SettingsContainerTests {
        @Test("Settings sidebar uses deterministic button selection")
        func settingsSidebarUsesDeterministicButtonSelection() throws {
            let source = try String(
                contentsOf: saneUIPackageRootURL()
                    .appendingPathComponent("Sources/SaneUI/Components/SaneSettingsContainer.swift"),
                encoding: .utf8
            )

            #expect(source.contains("HStack(spacing: 0)"))
            #expect(source.contains("ScrollViewReader { proxy in"))
            #expect(source.contains("ScrollView(.vertical, showsIndicators: false)"))
            #expect(source.contains("selection.wrappedValue = tab"))
            #expect(source.contains(".accessibilityAddTraits(selection.wrappedValue == tab ? .isSelected : [])"))
            #expect(source.contains(".id(tab.id)"))
            #expect(source.contains("didRevealInitialSidebarSelection"))
            #expect(source.contains("proxy.scrollTo(selectedTab.id, anchor: .center)"))
            #expect(source.contains("private struct SaneSettingsBackground: View"))
            #expect(source.contains("LinearGradient("))
            #expect(!source.contains("SaneGradientBackground"))
            #expect(!source.contains("VisualEffectBlur"))
            #expect(!source.contains("NavigationSplitView"))
            #expect(source.contains("public final class SaneSettingsWindow: NSWindow"))
            #expect(source.contains("override public func performKeyEquivalent(with event: NSEvent)"))
            #expect(source.contains("forwardPasteToFirstResponder()"))
            #expect(source.contains("#selector(NSText.paste(_:))"))
            #expect(!source.contains("case .about: .secondary"))
        }
    }

    @Suite("About License Catalog")
    struct AboutLicenseCatalogTests {
        @Test("Common license entries are centralized")
        func commonLicenseEntriesAreCentralized() {
            #expect(SaneAboutLicenseCatalog.sparkle.name == "Sparkle")
            #expect(SaneAboutLicenseCatalog.keyboardShortcuts.text == "MIT License")
            #expect(SaneAboutLicenseCatalog.saneUI.text == "PolyForm Shield 1.0.0")
        }
    }
#endif

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

    @Test("Welcome window supports persisting and restoring onboarding page state")
    func welcomeWindowSupportsResumingCurrentPage() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("private let onPageChange: ((Int) -> Void)?"))
        #expect(source.contains(".onAppear {\n            onPageChange?(currentPage)"))
        #expect(source.contains("EventTracker.logOnce(.onboardingStarted"))
        #expect(source.contains(".onChange(of: currentPage) { _, newValue in\n            onPageChange?(newValue)\n        }"))
        #expect(source.contains("initialPage: Int = 0,"))
        #expect(source.contains("onPageChange: ((Int) -> Void)? = nil"))
        #expect(source.contains("initialPage: initialPage,"))
        #expect(source.contains("onPageChange: onPageChange"))
    }

    @Test("Welcome window does not auto-dismiss active Pro trials")
    func welcomeWindowDoesNotAutoDismissActiveProTrials() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("guard !licenseService.isProTrialActive else { return }"))
    }

    @Test("Companion recommendations use app-specific visual cards")
    func companionRecommendationsUseVisualCards() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("private struct CompanionAppCard: View"))
        #expect(source.contains("Bundle.module.url(forResource: resourceName, withExtension: \"png\")"))
        #expect(source.contains("private struct CompanionIconImage: View"))
        #expect(source.contains("iconResourceName: theme.iconResourceName"))
        #expect(source.contains("Text(\"More helpful SaneApps\")"))
        #expect(source.contains("Text(\"Open\")"))
        #expect(source.contains("\"SaneBarIcon\""))
        #expect(source.contains("\"SaneClickIcon\""))
        #expect(source.contains("\"SaneClipIcon\""))
        #expect(source.contains("\"SaneHostsIcon\""))
        #expect(!source.contains(".font(.system(size: 11))"))
    }

    @Test("Onboarding primary buttons use the shared selected-control gradient")
    func onboardingPrimaryButtonsUseSelectedControlGradient() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("SaneGlassRoundedBackground("))
        #expect(source.contains("tint: SanePanelChrome.accentTeal"))
        #expect(source.contains("edgeTint: SanePanelChrome.accentHighlight"))
        #expect(!source.contains("colors: [saneAccentSoft.opacity(0.98), saneAccent.opacity(0.98)]"))
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
    @Test("Direct defaults use simple access labels")
    @MainActor
    func directDefaultsUseSimpleAccessLabels() {
        let service = LicenseService(
            appName: "SaneHosts",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanehosts"),
            keychain: MockKeychainService()
        )

        #expect(service.alternateUnlockLabel == "Unlock Pro")
        #expect(service.alternateEntryLabel == "Enter License Key")
        #expect(service.accessManagementLabel == "Deactivate Pro")
    }

    @Test("SaneVideo direct price matches the SaneApps Pro price")
    @MainActor
    func saneVideoDirectPriceMatchesSaneAppsProPrice() {
        let service = LicenseService(
            appName: "SaneVideo",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanevideo"),
            keychain: MockKeychainService()
        )

        #expect(service.displayPriceLabel == "$14.99")
    }

    @Test("Opt-in direct Pro trial starts automatically without a cached license")
    @MainActor
    func optInDirectProTrialStartsAutomaticallyWithoutCachedLicense() throws {
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        defer { unsetenv("SANEAPPS_FORCE_LICENSE_CHECK") }
        let suiteName = "tests.saneui.protrial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let keychain = MockKeychainService()

        let service = LicenseService(
            appName: "SaneHosts",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanehosts"),
            keychain: keychain,
            proTrial: .init(storageKeyPrefix: "tests.sanehosts.trial"),
            userDefaults: defaults
        )

        service.checkCachedLicense()

        #expect(!service.isLicensed)
        #expect(service.isPro)
        #expect(service.isProTrialActive)
        #expect(service.proAccessBadgeTitle == "Pro Trial")
        #expect(service.proTrialDaysRemaining == 14)
        #expect(defaults.object(forKey: "tests.sanehosts.trial.started_at") != nil)
        #expect(try keychain.string(forKey: "tests.sanehosts.trial.started_at") != nil)
    }

    @Test("Expired Pro trial removes Pro access")
    @MainActor
    func expiredProTrialRemovesProAccess() throws {
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        defer { unsetenv("SANEAPPS_FORCE_LICENSE_CHECK") }
        let suiteName = "tests.saneui.expiredtrial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let keychain = MockKeychainService()
        try keychain.set(String(Date().addingTimeInterval(-15 * 86400).timeIntervalSince1970), forKey: "tests.sanehosts.trial.started_at")

        let service = LicenseService(
            appName: "SaneHosts",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanehosts"),
            keychain: keychain,
            proTrial: .init(storageKeyPrefix: "tests.sanehosts.trial"),
            userDefaults: defaults
        )

        service.checkCachedLicense()

        #expect(!service.isLicensed)
        #expect(!service.isPro)
        #expect(!service.isProTrialActive)
        #expect(service.hasExpiredProTrial)
        #expect(service.proAccessDetail == "Trial ended")
    }

    @Test("Pro trial last-seen timestamp prevents clock rollback extension")
    @MainActor
    func proTrialLastSeenTimestampPreventsClockRollbackExtension() throws {
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        defer { unsetenv("SANEAPPS_FORCE_LICENSE_CHECK") }
        let suiteName = "tests.saneui.rollbacktrial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let keychain = MockKeychainService()
        try keychain.set(String(Date().addingTimeInterval(-13 * 86400).timeIntervalSince1970), forKey: "tests.sanehosts.trial.started_at")
        try keychain.set(String(Date().addingTimeInterval(2 * 86400).timeIntervalSince1970), forKey: "tests.sanehosts.trial.last_seen_at")

        let service = LicenseService(
            appName: "SaneHosts",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanehosts"),
            keychain: keychain,
            proTrial: .init(storageKeyPrefix: "tests.sanehosts.trial"),
            userDefaults: defaults
        )

        service.checkCachedLicense()

        #expect(!service.isLicensed)
        #expect(!service.isPro)
        #expect(!service.isProTrialActive)
        #expect(service.hasExpiredProTrial)
        #expect(service.proAccessDetail == "Trial ended")
    }

    @Test("Force-free mode disables active Pro trial access")
    @MainActor
    func forceFreeModeDisablesActiveProTrialAccess() throws {
        setenv("SANEAPPS_FORCE_FREE_MODE", "1", 1)
        setenv("SANEAPPS_FORCE_LICENSE_CHECK", "1", 1)
        defer {
            unsetenv("SANEAPPS_FORCE_FREE_MODE")
            unsetenv("SANEAPPS_FORCE_LICENSE_CHECK")
        }
        let suiteName = "tests.saneui.forcefree.trial.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let service = LicenseService(
            appName: "SaneHosts",
            checkoutURL: LicenseService.directCheckoutURL(appSlug: "sanehosts"),
            keychain: MockKeychainService(),
            proTrial: .init(storageKeyPrefix: "tests.sanehosts.trial"),
            userDefaults: defaults
        )

        service.checkCachedLicense()

        #expect(!service.isLicensed)
        #expect(!service.isPro)
        #expect(!service.isProTrialActive)
        #expect(defaults.object(forKey: "tests.sanehosts.trial.started_at") == nil)
    }

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
        #expect(service.hasCompletedPurchaseStateRefresh)
        #expect(service.validationError == nil)
        #expect(service.purchaseError == nil)
    }

    @Test("Debug force-pro override unlocks App Store builds deterministically")
    @MainActor
    func debugForceProOverrideUnlocksAppStoreBuildsDeterministically() {
        setenv("SANEAPPS_FORCE_PRO_MODE", "1", 1)
        defer { unsetenv("SANEAPPS_FORCE_PRO_MODE") }

        let service = LicenseService(
            appName: "SaneSales",
            purchaseBackend: .appStore(productID: "com.sanesales.app.pro.unlock.v2"),
            keychain: MockKeychainService()
        )

        service.checkCachedLicense()

        #expect(service.isLicensed)
        #expect(service.isPro)
        #expect(service.hasCompletedPurchaseStateRefresh)
        #expect(service.validationError == nil)
        #expect(service.purchaseError == nil)
    }

    @Test("App Store purchase state remains pending until entitlement refresh")
    @MainActor
    func appStorePurchaseStateRemainsPendingUntilEntitlementRefresh() {
        let service = LicenseService(
            appName: "SaneSales",
            purchaseBackend: .appStore(productID: "com.sanesales.app.pro.unlock.v2"),
            keychain: MockKeychainService()
        )

        service.checkCachedLicense()

        #expect(!service.hasCompletedPurchaseStateRefresh)
    }

    @Test("App Store backend listens for transaction updates and active refreshes")
    func appStoreBackendListensForTransactionUpdatesAndActiveRefreshes() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/LicenseService.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Transaction.updates"))
        #expect(source.contains("Transaction.unfinished"))
        #expect(source.contains("Transaction.latest(for: productID)"))
        #expect(source.contains("didBecomeActiveNotification"))
        #expect(source.contains("configureAppStoreObservationIfNeeded()"))
    }
}

@Suite("Shared License UI Policy")
struct SharedLicenseUIPolicyTests {
    @Test("Shared upsell uses entry label for direct key path")
    func sharedUpsellUsesEntryLabelForDirectKeyPath() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/ProUpsellView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Button(licenseService.alternateEntryLabel)"))
        #expect(!source.contains("Button(licenseService.alternateUnlockLabel)"))
    }

    @Test("Shared upsell does not stack a nested license sheet")
    func sharedUpsellAvoidsNestedLicenseSheet() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/ProUpsellView.swift"),
            encoding: .utf8
        )

        #expect(!source.contains(".sheet(isPresented: $showingLicenseEntry)"))
        #expect(source.contains("case .licenseEntry"))
        #expect(source.contains("LicenseEntryView("))
    }

    @Test("License gate uses entry label for direct key flow")
    func licenseGateUsesEntryLabelForDirectKeyFlow() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/LicenseGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Text(licenseService.alternateEntryLabel)"))
        #expect(!source.contains("Text(licenseService.alternateUnlockLabel)"))
    }

    @Test("License gate asks for support after expired direct trial")
    func licenseGateAsksForSupportAfterExpiredDirectTrial() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/LicenseGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Mr. Sane here. I need to share an insane stat with you all."))
        #expect(source.contains("Across SaneApps Mac apps: 100,000+ downloads in 180 days."))
        #expect(source.contains("Fewer than 0.5% led to purchases."))
        #expect(source.contains("Kind reviews mean a lot, but they can't sustain these apps."))
        #expect(source.contains("\\\"The worker is worthy of his wages.\\\""))
        #expect(source.contains("Sincerely,"))
        #expect(source.contains("1 Timothy 5:18"))
        #expect(source.contains("!licenseService.usesAppStorePurchase && !licenseService.usesSetappPurchase"))
        #expect(source.contains("return \"Buy Pro\""))
        #expect(source.contains("Text(Self.directSupportLabel())"))
        #expect(source.contains("Self.directSupportURL()"))
        #expect(source.contains("@inline(never)\n    private static func directSupportString"))
        #expect(source.contains("@inline(never)\n    private static func directSupportByte"))
        #expect(!source.contains("private static let donationLabel"))
        #expect(!source.contains("private static let donationURL"))
        #expect(!source.contains("\"https://github.com/sponsors/MrSaneApps\""))
        #expect(!source.contains("Text(\"Donate\")"))
        #expect(source.contains("Text(\"Enter License\")"))
        #expect(source.contains("Text(\"Quit\")"))
        #expect(!source.contains("To continue using \\(licenseService.appName), please purchase a license."))
    }

    @Test("Welcome gate uses entry label for direct key flow")
    func welcomeGateUsesEntryLabelForDirectKeyFlow() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Button(licenseService.alternateEntryLabel)"))
        #expect(!source.contains("Button(licenseService.alternateUnlockLabel)"))
    }

    @Test("Welcome gate cross-sell stays direct and excludes weak-fit apps")
    func welcomeGateCrossSellStaysDirectAndFocused() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("!licenseService.usesAppStorePurchase && !licenseService.usesSetappPurchase"))
        #expect(source.contains("case \"saneclick\""))
        #expect(source.contains("case \"saneclip\""))
        #expect(source.contains("case \"sanehosts\""))
        #expect(source.contains("Text(\"More helpful SaneApps\")"))
        #expect(source.contains("runSingleOutboundAction"))
        #expect(!source.contains("companion(\"SaneSales\""))
        #expect(!source.contains("companion(\"SaneVideo\""))
        #expect(!source.contains("Text(\"Works well with\")"))
        #expect(!source.contains("Text(\"Also useful\")"))
    }

    @Test("Welcome gate keeps Setapp purchase card channel-correct")
    func welcomeGateKeepsSetappPurchaseCardChannelCorrect() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/WelcomeGateView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("if licenseService.usesSetappPurchase"))
        #expect(source.contains("Text(\"Included with Setapp\")"))
        #expect(source.contains("Text(\"Pro access is managed by Setapp.\")"))
        #expect(source.contains("EventTracker.log(\"app_store_purchase_clicked\""))
        #expect(source.contains("currentPage = max(0, currentPage - 1)"))
        #expect(source.contains("currentPage = min(totalPages - 1, currentPage + 1)"))
    }

    @Test("License entry supports shared close and back behavior")
    func licenseEntrySupportsSharedCloseAndBackBehavior() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/LicenseEntryView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("private let onClose: (() -> Void)?"))
        #expect(source.contains("private let onBack: (() -> Void)?"))
        #expect(source.contains(".saneOnExitCommand { closeView() }"))
        #expect(source.contains("Button(onBack == nil ? \"Cancel\" : \"Back\")"))
    }

    @Test("License entry gives clipboard and focus fallback for direct key entry")
    func licenseEntryGivesClipboardAndFocusFallbackForDirectKeyEntry() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/LicenseEntryView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("@FocusState private var licenseFieldFocused"))
        #expect(source.contains("SaneLicenseKeyTextField("))
        #expect(source.contains("SaneLicensePasteButton(onPaste: pasteLicenseKeyFromClipboard)"))
        #expect(source.contains("func makeNSView(context: Context) -> NSButton"))
        #expect(source.contains("button.action = #selector(Coordinator.pressPasteButton(_:))"))
        #expect(source.contains("keyboardPasteShortcut"))
        #expect(source.contains(".keyboardShortcut(\"v\", modifiers: .command)"))
        #expect(source.contains(".accessibilityElement(children: .ignore)"))
        #expect(source.contains("PasteAwareTextField"))
        #expect(source.contains("PasteAwareTextFieldCell"))
        #expect(source.contains("PasteAwareFieldEditor"))
        #expect(source.contains("override func fieldEditor(for controlView: NSView)"))
        #expect(source.contains("override func keyDown(with event: NSEvent)"))
        #expect(source.contains("override func performKeyEquivalent(with event: NSEvent)"))
        #expect(source.contains("flags.contains(.command)"))
        #expect(source.contains("flags.intersection([.option, .control]).isEmpty"))
        #expect(source.contains("SaneLicenseEditMenu.ensureInstalled()"))
        #expect(source.contains("NSApp.mainMenu = NSMenu()"))
        #expect(source.contains("SaneLicenseEditCommandTarget.shared.registerPasteHandler"))
        #expect(source.contains("#selector(SaneLicenseEditCommandTarget.paste(_:))"))
        #expect(source.contains("SaneLicenseEditMenu.updatePasteTarget()"))
        #expect(source.contains("focusLicenseField()"))
        #expect(source.contains("pasteLicenseKeyFromClipboard()"))
        #expect(source.contains("NSPasteboard.general.string(forType: .string)"))
        #expect(source.contains("UIPasteboard.general.string"))
        #expect(source.contains("accessibilityIdentifier(\"saneui-license-paste\")"))
        #expect(source.contains("accessibilityLabel(\"Paste License Key\")"))
        #expect(source.contains(".saneOnKeyDown { handleKeyCommand($0) }"))
        #expect(source.contains("event.keyCode == 9"))
        #expect(source.contains("NSApp.setActivationPolicy(.regular)"))
        #expect(source.contains("NSApp.activate(ignoringOtherApps: true)"))
        #expect(source.contains("NSApp.setActivationPolicy(previousActivationPolicy)"))
        #expect(source.contains("NSEvent.addLocalMonitorForEvents(matching: .keyDown)"))
        #expect(source.contains("NSEvent.addGlobalMonitorForEvents(matching: .keyDown)"))
        #expect(source.contains("removePasteMonitors()"))
    }

    @Test("Shared upsell handles keyboard dismissal directly")
    func sharedUpsellHandlesKeyboardDismissalDirectly() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/ProUpsellView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("private func handleKeyCommand(_ event: NSEvent) -> Bool"))
        #expect(source.contains(".saneOnKeyDown { handleKeyCommand($0) }"))
        #expect(source.contains("if event.keyCode == 53"))
        #expect(source.contains("let isCommandW = flags == [.command]"))
    }
}

#if canImport(AppKit)
    @Suite("Settings Icon Semantics")
    struct SaneSettingsIconSemanticTests {
        @Test("Shared settings semantics keep stable colors")
        func sharedSettingsSemanticsKeepStableColors() {
            #expect(hex(SaneSettingsIconSemantic.general.color) == "AEB8C7")
            #expect(hex(SaneSettingsIconSemantic.rules.color) == "FFB042")
            #expect(hex(SaneSettingsIconSemantic.appearance.color) == "C793FA")
            #expect(hex(SaneSettingsIconSemantic.shortcuts.color) == "61B8FF")
            #expect(hex(SaneSettingsIconSemantic.content.color) == "61D98F")
            #expect(hex(SaneSettingsIconSemantic.sync.color) == "52E0F0")
            #expect(hex(SaneSettingsIconSemantic.storage.color) == "F58A3D")
            #expect(hex(SaneSettingsIconSemantic.license.color) == "FFD62E")
            #expect(hex(SaneSettingsIconSemantic.about.color) == "CAD9EB")
        }

        @Test("Core settings tabs stay visually distinct")
        func coreSettingsTabsStayVisuallyDistinct() {
            let coreHexes = [
                hex(SaneSettingsIconSemantic.general.color),
                hex(SaneSettingsIconSemantic.shortcuts.color),
                hex(SaneSettingsIconSemantic.license.color),
                hex(SaneSettingsIconSemantic.about.color)
            ]

            #expect(Set(coreHexes).count == coreHexes.count)
        }

        private func hex(_ color: Color) -> String {
            let resolved = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor(color)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            return String(
                format: "%02X%02X%02X",
                Int(round(red * 255)),
                Int(round(green * 255)),
                Int(round(blue * 255))
            )
        }
    }
#endif

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

    @Test("Funnel event names are stable for aggregate analytics")
    func funnelEventNamesAreStable() {
        #expect(EventTracker.FunnelEvent.onboardingStarted.rawValue == "onboarding_started")
        #expect(EventTracker.FunnelEvent.onboardingCompleted.rawValue == "onboarding_completed")
        #expect(EventTracker.FunnelEvent.demoStarted.rawValue == "demo_started")
        #expect(EventTracker.FunnelEvent.providerConnectStarted.rawValue == "provider_connect_started")
        #expect(EventTracker.FunnelEvent.providerConnectSuccess.rawValue == "provider_connect_success")
        #expect(EventTracker.FunnelEvent.providerConnectFailed.rawValue == "provider_connect_failed")
        #expect(EventTracker.FunnelEvent.paywallSeen.rawValue == "paywall_seen")
        #expect(EventTracker.FunnelEvent.checkoutClicked.rawValue == "checkout_clicked")
        #expect(EventTracker.FunnelEvent.firstValueAction.rawValue == "first_value_action")
    }

    @Test("Once key contains no unique identifier")
    func onceKeyContainsNoUniqueIdentifier() {
        #expect(
            EventTracker.onceKey(app: " SaneClip ", event: " Onboarding_Started ")
                == "SaneApps.EventTracker.logged.saneclip.onboarding_started"
        )
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

    @Test("Move-to-Applications skip policy is explicit")
    func applicationMoverSkipPolicy() {
        #expect(SaneApplicationMover.shouldSkipMove(environment: ["SANEAPPS_SKIP_MOVE_TO_APPLICATIONS": "1"], arguments: []))
        #expect(SaneApplicationMover.shouldSkipMove(environment: [:], arguments: ["SaneBar", "--sane-skip-app-move"]))
        #expect(!SaneApplicationMover.shouldSkipMove(environment: [:], arguments: ["SaneBar"]))
    }

    @Test("Move-to-Applications candidates include system and user Applications folders")
    func applicationMoverDestinationCandidates() {
        let candidates = SaneApplicationMover.destinationCandidates(
            appBundleName: "SaneBar.app",
            homeDirectory: "/Users/tester"
        )

        #expect(candidates.map(\.url.path) == [
            "/Applications/SaneBar.app",
            "/Users/tester/Applications/SaneBar.app"
        ])
    }

    @Test("Move-to-Applications copies to user Applications when system Applications is unavailable")
    func applicationMoverFallsBackToUserApplications() throws {
        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent("SaneApplicationMoverTests-\(UUID().uuidString)", isDirectory: true)
        let sourceURL = rootURL.appendingPathComponent("Downloads/SaneBar.app", isDirectory: true)
        let sourceContentsURL = sourceURL.appendingPathComponent("Contents", isDirectory: true)
        let homeURL = rootURL.appendingPathComponent("Home", isDirectory: true)
        let missingSystemApplications = rootURL.appendingPathComponent("MissingSystemApplications", isDirectory: true)
        defer { try? fileManager.removeItem(at: rootURL) }

        try fileManager.createDirectory(at: sourceContentsURL, withIntermediateDirectories: true)
        try "bundle".write(to: sourceContentsURL.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)

        let destinationURL = SaneApplicationMover.copyAppBundleToInstalledLocation(
            sourceURL: sourceURL,
            appBundleName: "SaneBar.app",
            homeDirectory: homeURL.path,
            systemApplicationsDirectory: missingSystemApplications.path
        )

        #expect(destinationURL?.path == homeURL.appendingPathComponent("Applications/SaneBar.app", isDirectory: true).path)
        #expect(fileManager.fileExists(atPath: sourceURL.path))
        #expect(fileManager.fileExists(atPath: homeURL.appendingPathComponent("Applications/SaneBar.app/Contents/Info.plist").path))
    }

    @Test("Move-to-Applications preserves existing install when replacement copy fails")
    func applicationMoverPreservesExistingInstallWhenCopyFails() throws {
        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent("SaneApplicationMoverTests-\(UUID().uuidString)", isDirectory: true)
        let missingSourceURL = rootURL.appendingPathComponent("Downloads/MissingSaneBar.app", isDirectory: true)
        let homeURL = rootURL.appendingPathComponent("Home", isDirectory: true)
        let systemApplicationsURL = rootURL.appendingPathComponent("Applications", isDirectory: true)
        let existingInfoURL = systemApplicationsURL
            .appendingPathComponent("SaneBar.app/Contents/Info.plist", isDirectory: false)
        defer { try? fileManager.removeItem(at: rootURL) }

        try fileManager.createDirectory(at: existingInfoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "existing".write(to: existingInfoURL, atomically: true, encoding: .utf8)

        let destinationURL = SaneApplicationMover.copyAppBundleToInstalledLocation(
            sourceURL: missingSourceURL,
            appBundleName: "SaneBar.app",
            homeDirectory: homeURL.path,
            systemApplicationsDirectory: systemApplicationsURL.path
        )

        #expect(destinationURL == nil)
        #expect(try (String(contentsOf: existingInfoURL, encoding: .utf8)) == "existing")
    }

    @Test("Move-to-Applications swaps existing install only after replacement copy succeeds")
    func applicationMoverSwapsExistingInstallAfterCopySucceeds() throws {
        let fileManager = FileManager.default
        let rootURL = fileManager.temporaryDirectory
            .appendingPathComponent("SaneApplicationMoverTests-\(UUID().uuidString)", isDirectory: true)
        let sourceInfoURL = rootURL
            .appendingPathComponent("Downloads/SaneBar.app/Contents/Info.plist", isDirectory: false)
        let homeURL = rootURL.appendingPathComponent("Home", isDirectory: true)
        let systemApplicationsURL = rootURL.appendingPathComponent("Applications", isDirectory: true)
        let existingInfoURL = systemApplicationsURL
            .appendingPathComponent("SaneBar.app/Contents/Info.plist", isDirectory: false)
        defer { try? fileManager.removeItem(at: rootURL) }

        try fileManager.createDirectory(at: sourceInfoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: existingInfoURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "new".write(to: sourceInfoURL, atomically: true, encoding: .utf8)
        try "existing".write(to: existingInfoURL, atomically: true, encoding: .utf8)

        let destinationURL = SaneApplicationMover.copyAppBundleToInstalledLocation(
            sourceURL: sourceInfoURL.deletingLastPathComponent().deletingLastPathComponent(),
            appBundleName: "SaneBar.app",
            homeDirectory: homeURL.path,
            systemApplicationsDirectory: systemApplicationsURL.path
        )

        #expect(destinationURL?.path == systemApplicationsURL.appendingPathComponent("SaneBar.app", isDirectory: true).path)
        #expect(try (String(contentsOf: existingInfoURL, encoding: .utf8)) == "new")
    }
}

// SaneSparkleRow + SaneSparkleCheckFrequency moved OUT of the shared SaneUI
// library (2026-07-01): Setapp's archive scanner rightly forbids Sparkle
// settings-UI symbols in Setapp binaries, and a shared-library type reaches
// every consumer's binary regardless of app-side #if gating. The component
// now lives in Sources/SaneUICatalog (demo) and as channel-gated app-local
// copies in direct-channel apps (SaneClip UI/Settings/SaneSparkleRow.swift;
// SaneBar will need the same copy when it next bumps its SaneUI pin).
// Behavioral enum tests moved with the code (SaneClip Tests).

@Test("Shared SaneUI library does not publish Sparkle settings UI symbols")
func sharedLibraryDoesNotPublishSparkleSettingsSymbols() throws {
    let sourceRoot = saneUIPackageRootURL().appendingPathComponent("Sources/SaneUI")
    let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey]
    guard let enumerator = FileManager.default.enumerator(
        at: sourceRoot,
        includingPropertiesForKeys: Array(resourceKeys)
    ) else {
        Issue.record("Unable to enumerate \(sourceRoot.path)")
        return
    }

    var matches: [String] = []
    for case let url as URL in enumerator where url.pathExtension == "swift" {
        let values = try url.resourceValues(forKeys: resourceKeys)
        guard values.isRegularFile == true else { continue }

        let source = try String(contentsOf: url, encoding: .utf8)
        if source.contains("SaneSparkleRow") || source.contains("SaneSparkleCheckFrequency") {
            matches.append(url.path.replacingOccurrences(of: sourceRoot.path + "/", with: ""))
        }
    }

    #expect(matches.isEmpty, "Sparkle settings UI must stay app-local, not in SaneUI: \(matches.joined(separator: ", "))")
}

@Suite("Update Eligibility")
struct SaneUpdateEligibilityTests {
    @Test("Release bundle in Applications is update eligible")
    func releaseBundleInApplicationsIsEligible() {
        #expect(SaneUpdateEligibility.resolve(
            bundleIdentifier: "com.sanebar.app",
            releaseBundleIdentifier: "com.sanebar.app",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester"
        ) == .eligible)
    }

    @Test("Release bundle in user Applications is update eligible")
    func releaseBundleInUserApplicationsIsEligible() {
        #expect(SaneUpdateEligibility.resolve(
            bundleIdentifier: "com.sanebar.app",
            releaseBundleIdentifier: "com.sanebar.app",
            bundlePath: "/Users/tester/Applications/SaneBar.app",
            homeDirectory: "/Users/tester"
        ) == .eligible)
    }

    @Test("Release bundle outside Applications is not update eligible")
    func releaseBundleOutsideApplicationsIsNotEligible() {
        let eligibility = SaneUpdateEligibility.resolve(
            bundleIdentifier: "com.sanebar.app",
            releaseBundleIdentifier: "com.sanebar.app",
            bundlePath: "/Users/tester/Downloads/SaneBar.app",
            homeDirectory: "/Users/tester"
        )

        #expect(eligibility == .notInstalledInApplications)
        #expect(!eligibility.canUseInAppUpdates)
        #expect(eligibility.userFacingStatus == "Updates are available after the app is opened from your Applications folder.")
    }

    @Test("Dev bundle is not update eligible")
    func devBundleIsNotEligible() {
        #expect(SaneUpdateEligibility.resolve(
            bundleIdentifier: "com.sanebar.dev",
            releaseBundleIdentifier: "com.sanebar.app",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester"
        ) == .nonReleaseBundle)
    }
}

@Suite("Background App Defaults")
struct SaneBackgroundAppDefaultsTests {
    @Test("Background apps default to hidden Dock icon and consented login prompt")
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

    @Test("Default login prompt is offered only from an eligible unregistered install")
    func defaultLoginPromptOfferPolicy() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        #expect(SaneLoginItemPolicy.shouldOfferDefaultPrompt(
            markerKey: "prompted",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered }
        ))
        #expect(!SaneLoginItemPolicy.shouldOfferDefaultPrompt(
            markerKey: "prompted",
            bundlePath: "/Users/tester/Downloads/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered }
        ))
        #expect(!SaneLoginItemPolicy.shouldOfferDefaultPrompt(
            markerKey: "prompted",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .enabled }
        ))

        defaults.set(true, forKey: "prompted")
        #expect(!SaneLoginItemPolicy.shouldOfferDefaultPrompt(
            markerKey: "prompted",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered }
        ))
    }

    @Test("Accepted default login prompt registers the app")
    @MainActor
    func acceptedDefaultLoginPromptRegistersTheApp() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        var promptCount = 0
        var registerCount = 0
        let result = SaneLoginItemPolicy.offerDefaultLaunchAtLoginIfNeeded(
            appName: "SaneBar",
            markerKey: "prompted",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered },
            prompt: { appName in
                promptCount += 1
                return appName == "SaneBar"
            },
            register: { registerCount += 1 },
            failurePresenter: { _ in }
        )

        #expect(result == .enabled)
        #expect(promptCount == 1)
        #expect(registerCount == 1)
        #expect(defaults.bool(forKey: "prompted"))
    }

    @Test("Declined default login prompt does not register")
    @MainActor
    func declinedDefaultLoginPromptDoesNotRegister() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        var registerCount = 0
        let result = SaneLoginItemPolicy.offerDefaultLaunchAtLoginIfNeeded(
            appName: "SaneBar",
            markerKey: "prompted",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            statusProvider: { .notRegistered },
            prompt: { _ in false },
            register: { registerCount += 1 },
            failurePresenter: { _ in }
        )

        #expect(result == .declined)
        #expect(registerCount == 0)
        #expect(defaults.bool(forKey: "prompted"))
    }

    @Test("Login item toggle explains ineligible install locations")
    func loginItemToggleExplainsIneligibleInstallLocations() throws {
        let source = try String(
            contentsOf: URL(fileURLWithPath: #filePath)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Sources/SaneUI/Components/SaneLoginItemToggle.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Start at login is available after the app is opened from your Applications folder."))
        #expect(source.contains("SaneInlineHelp(statusMessage)"))
    }

    @Test("Explicit login item choice is recorded")
    func explicitLoginItemChoiceIsRecorded() throws {
        let defaults = try #require(UserDefaults(suiteName: #function))
        defaults.removePersistentDomain(forName: #function)
        defer { defaults.removePersistentDomain(forName: #function) }

        var unregisterCount = 0
        var registerCount = 0

        let didApplyChoice = try SaneLoginItemPolicy.setEnabled(
            false,
            markerKey: "hasAnsweredLaunchAtLoginDefaultPrompt",
            bundlePath: "/Applications/SaneBar.app",
            homeDirectory: "/Users/tester",
            userDefaults: defaults,
            register: { registerCount += 1 },
            unregister: { unregisterCount += 1 }
        )

        #expect(didApplyChoice)
        #expect(defaults.bool(forKey: "hasAnsweredLaunchAtLoginDefaultPrompt"))
        #expect(unregisterCount == 1)
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

    @Test("License metadata must match the app product")
    @MainActor
    func licenseMetadataMustMatchAppProduct() {
        #expect(LicenseService.licenseProductMatchesApp(appName: "SaneVideo", productName: "SaneVideo", variantName: "Pro"))
        #expect(!LicenseService.licenseProductMatchesApp(appName: "SaneVideo", productName: "SaneBar", variantName: "Pro"))
        #expect(!LicenseService.licenseProductMatchesApp(appName: "SaneVideo", productName: nil, variantName: nil))
    }

    @Test("License input extracts forwarded receipt keys")
    @MainActor
    func licenseInputExtractsForwardedReceiptKeys() {
        let key = "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE"
        #expect(LicenseService.normalizedLicenseKeyInput("License key:\n\(key)\u{200B}") == key)
        #expect(LicenseService.normalizedLicenseKeyInput("aaaaaaaa–bbbb–4ccc–8ddd–eeeeeeeeeeee") == key)
        #expect(LicenseService.normalizedLicenseKeyInput("  \(key.prefix(8)) \n-\tBBBB-4CCC-8DDD-EEEEEEEEEEEE  ") == key)
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

    @Test("Diagnostics markdown redacts sensitive public issue data")
    func markdownRedactsSensitivePublicIssueData() {
        let report = SaneDiagnosticReport(
            appName: "SaneBar",
            appVersion: "2.1.28",
            buildNumber: "2128",
            platformDescription: "macOS 26.3.1",
            deviceDescription: "Macmini9,1 (Apple Silicon)",
            recentLogs: [
                .init(timestamp: Date(timeIntervalSince1970: 1), level: "INFO", message: "opened /Volumes/ClientDrive/Acme Secret/foo.mov for jane@example.com")
            ],
            settingsSummary: "exportPath: /Users/alex/Projects/PrivateClient\napiKey: sk_test_12345678901234567890",
            collectedAt: Date(timeIntervalSince1970: 2)
        )

        let markdown = report.toMarkdown(userDescription: "video at file:///Users/alex/Desktop/private.mov failed")

        #expect(markdown.contains("[REDACTED_PATH]"))
        #expect(markdown.contains("[REDACTED_FILE_URL]"))
        #expect(markdown.contains("[REDACTED_EMAIL]"))
        #expect(markdown.contains("apiKey: [REDACTED]"))
        #expect(!markdown.contains("ClientDrive"))
        #expect(!markdown.contains("jane@example.com"))
        #expect(!markdown.contains("/Users/alex"))
        #expect(!markdown.contains("sk_test_12345678901234567890"))
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

    @Test("Attachment package includes diagnostics and selected files")
    @MainActor
    func attachmentPackageIncludesDiagnosticsAndFiles() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }

        let source = base.appendingPathComponent("screen.png")
        try Data("image-data".utf8).write(to: source)

        let report = SaneDiagnosticReport(
            appName: "SaneBar",
            appVersion: "2.1.48",
            buildNumber: "2148",
            platformDescription: "macOS 26.4",
            deviceDescription: "Mac",
            recentLogs: [],
            settingsSummary: "state: expanded",
            collectedAt: Date(timeIntervalSince1970: 0)
        )

        let package = try SaneFeedbackView.prepareAttachmentPackage(
            report: report,
            userDescription: "Visual glitch",
            attachmentURLs: [source],
            baseDirectory: base
        )

        let diagnostics = try String(contentsOf: package.appendingPathComponent("diagnostics.md"), encoding: .utf8)
        let copiedAttachment = package.appendingPathComponent("screen.png")

        #expect(diagnostics.contains("Visual glitch"))
        #expect(FileManager.default.fileExists(atPath: copiedAttachment.path))
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
        case let .direct(checkoutURL):
            #expect(checkoutURL == LicenseService.directCheckoutURL(appSlug: "sanehosts"))
        case .appStore, .setapp:
            Issue.record("Direct bundle unexpectedly inferred App Store purchase backend")
        }
    }

    @Test("Bundle with AppStoreProductID and Sparkle framework stays direct")
    @MainActor
    func directBundleWithSparkleFrameworkStaysDirect() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("app")
        let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let frameworksURL = contentsURL.appendingPathComponent("Frameworks", isDirectory: true)
        let sparkleURL = frameworksURL.appendingPathComponent("Sparkle.framework", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")

        try FileManager.default.createDirectory(at: sparkleURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }

        let info: [String: Any] = [
            "CFBundleIdentifier": "com.saneapps.directbundle",
            "AppStoreProductID": "com.saneapps.direct.pro"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(to: infoURL)

        guard let bundle = Bundle(url: bundleURL) else {
            Issue.record("Expected temporary app bundle to load")
            return
        }

        let backend = LicenseService.inferredPurchaseBackend(
            appName: "SaneSales",
            directCheckoutURL: LicenseService.directCheckoutURL(appSlug: "sanesales"),
            bundle: bundle
        )

        switch backend {
        case let .direct(checkoutURL):
            #expect(checkoutURL == LicenseService.directCheckoutURL(appSlug: "sanesales"))
        case .appStore, .setapp:
            Issue.record("Direct bundle with Sparkle unexpectedly inferred App Store purchase backend")
        }
    }

    @Test("Explicit direct bundle marker overrides AppStoreProductID without Sparkle")
    @MainActor
    func explicitDirectBundleMarkerOverridesAppStoreProductIDWithoutSparkle() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("app")
        let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")

        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }

        let info: [String: Any] = [
            "CFBundleIdentifier": "com.saneapps.directbundle",
            "AppStoreProductID": "com.saneapps.direct.pro",
            "SaneDistributionChannel": "direct"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(to: infoURL)

        guard let bundle = Bundle(url: bundleURL) else {
            Issue.record("Expected temporary app bundle to load")
            return
        }

        let backend = LicenseService.inferredPurchaseBackend(
            appName: "SaneSales",
            directCheckoutURL: LicenseService.directCheckoutURL(appSlug: "sanesales"),
            bundle: bundle
        )

        switch backend {
        case let .direct(checkoutURL):
            #expect(checkoutURL == LicenseService.directCheckoutURL(appSlug: "sanesales"))
        case .appStore, .setapp:
            Issue.record("Explicit direct marker should override AppStoreProductID without Sparkle")
        }
    }

    @Test("Bundle with AppStoreProductID and no Sparkle stays App Store")
    @MainActor
    func appStoreBundleWithoutSparkleStaysAppStore() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("app")
        let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")

        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }

        let info: [String: Any] = [
            "CFBundleIdentifier": "com.saneapps.appstorebundle",
            "AppStoreProductID": "com.saneapps.sales.pro"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(to: infoURL)

        guard let bundle = Bundle(url: bundleURL) else {
            Issue.record("Expected temporary app bundle to load")
            return
        }

        let backend = LicenseService.inferredPurchaseBackend(
            appName: "SaneSales",
            directCheckoutURL: LicenseService.directCheckoutURL(appSlug: "sanesales"),
            bundle: bundle
        )

        switch backend {
        case let .appStore(productID):
            #expect(productID == "com.saneapps.sales.pro")
        case .direct, .setapp:
            Issue.record("App Store bundle unexpectedly inferred direct purchase backend")
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

    @Test("Version line respects explicit override")
    func versionLineUsesOverride() {
        #expect(SaneAboutViewPolicy.versionLine(override: "Shared Source of Truth") == "Shared Source of Truth")
    }

    @Test("Version line falls back to bundle version")
    func versionLineUsesBundleVersion() throws {
        let bundleURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("bundle")
        let contentsURL = bundleURL.appendingPathComponent("Contents", isDirectory: true)
        let infoURL = contentsURL.appendingPathComponent("Info.plist")

        try FileManager.default.createDirectory(at: contentsURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: bundleURL) }

        let info: [String: Any] = [
            "CFBundleIdentifier": "com.saneapps.testbundle",
            "CFBundleShortVersionString": "9.9.9"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(to: infoURL)

        let bundle = try #require(Bundle(url: bundleURL))
        #expect(SaneAboutViewPolicy.versionLine(bundle: bundle) == "Version 9.9.9")
    }

    @Test("About trust copy matches shared standard")
    func aboutTrustCopyMatchesStandard() {
        #expect(SaneAboutViewPolicy.primaryTrustPrefix == "Made with")
        #expect(SaneAboutViewPolicy.primaryTrustSuffix == "in the USA")
        #expect(SaneAboutViewPolicy.secondaryTrustLine == "On-Device by Default · No Personal Data")
    }

    @Test("Repository URL stays on sane-apps org")
    func repositoryURLUsesSaneAppsOrg() {
        #expect(SaneAboutViewPolicy.repositoryURL(githubRepo: "SaneUI")?.absoluteString == "https://github.com/sane-apps/SaneUI")
    }

    @Test("Issues URL stays on the shared issues route")
    func issuesURLUsesIssuesRoute() {
        #expect(SaneAboutViewPolicy.issuesURL(githubRepo: "SaneUI")?.absoluteString == "https://github.com/sane-apps/SaneUI/issues")
    }
}

@Suite("Feedback Copy")
struct SaneFeedbackCopyTests {
    @Test("Privacy line matches shared standard")
    func privacyLineMatchesSharedStandard() {
        #expect(SaneFeedbackCopy.privacyLine.contains("Nothing is sent automatically"))
        #expect(SaneFeedbackCopy.privacyLine.contains("GitHub issues are public"))
        #expect(SaneFeedbackCopy.privacyLine.contains("email for sensitive logs or media"))
    }

    @Test("Feedback copy says media is prepared locally, not auto-uploaded")
    func feedbackCopyExplainsLocalMediaPackage() {
        #expect(SaneFeedbackCopy.subtitle.contains("selected media is prepared in a local folder"))
        #expect(SaneFeedbackCopy.mediaInstruction.contains("drag prepared files into the issue"))
        #expect(SaneFeedbackCopy.mediaInstruction.contains("large videos"))
        #expect(SaneFeedbackCopy.mediaInstruction.contains("file-sharing link"))
    }

    @Test("Feedback view exposes media attachment workflow")
    func feedbackViewExposesMediaAttachments() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/Components/SaneFeedbackView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Photos and Videos"))
        #expect(source.contains("NSOpenPanel"))
        #expect(source.contains("prepareAttachmentPackage"))
        #expect(source.contains("SaneFeedbackCopy.mediaInstruction"))
        #expect(source.contains("reportErrorMessage"))
        #expect(!source.contains("try? Self.prepareAttachmentPackage"))
        #expect(source.contains("if selectedAttachmentURLs.isEmpty {\n                dismiss()"))
    }

    @Test("Feedback view has explicit escape paths")
    func feedbackViewHasExplicitEscapePaths() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/Components/SaneFeedbackView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("Image(systemName: \"xmark.circle.fill\")"))
        #expect(source.contains("Button(\"Cancel\")"))
        #expect(source.contains(".keyboardShortcut(.cancelAction)"))
    }
}

@Suite("License Settings Layout")
struct LicenseSettingsLayoutTests {
    @Test("Panel actions use adaptive fitted labels")
    func panelActionsUseAdaptiveFittedLabels() throws {
        let source = try String(
            contentsOf: saneUIPackageRootURL()
                .appendingPathComponent("Sources/SaneUI/License/LicenseSettingsView.swift"),
            encoding: .utf8
        )

        #expect(source.contains("ViewThatFits(in: .horizontal)"))
        #expect(source.contains("fittedActionLabel"))
        #expect(source.contains(".minimumScaleFactor(0.84)"))
        #expect(source.contains("licenseService.isProTrialActive"))
        #expect(source.contains("directTrialActions"))
        #expect(source.contains("accessibilityIdentifier(\"saneui-license-enter-key\")"))
        #expect(source.contains("accessibilityIdentifier(\"saneui-license-deactivate\")"))
        #expect(source.contains(".accessibilityLabel(labels.directEntryLabel ?? licenseService.alternateEntryLabel)"))
        #expect(source.contains(".accessibilityLabel(labels.directManagementLabel ?? licenseService.accessManagementLabel)"))
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

#if canImport(AppKit)
    @MainActor
    private final class StandardMenuTarget: NSObject {
        @objc func openApp(_: Any?) {}
        @objc func openSettings(_: Any?) {}
        @objc func checkForUpdates(_: Any?) {}
        @objc func license(_: Any?) {}
        @objc func about(_: Any?) {}
        @objc func whatsNew(_: Any?) {}
        @objc func quit(_: Any?) {}
    }

    @MainActor
    @Suite("Standard Menu Policy")
    struct SaneStandardMenuPolicyTests {
        @Test("Settings item uses the shared title and command shortcut")
        func settingsItemUsesSharedTitleAndShortcut() {
            let target = StandardMenuTarget()
            let item = SaneStandardMenu.settingsItem(
                target: target,
                action: #selector(StandardMenuTarget.openSettings(_:))
            )

            #expect(item.title == "Settings...")
            #expect(item.keyEquivalent == ",")
            #expect(item.keyEquivalentModifierMask.contains(.command))
            #expect(item.action == #selector(StandardMenuTarget.openSettings(_:)))
            #expect(item.target === target)
        }

        @Test("Dock settings item can omit the keyboard shortcut")
        func dockSettingsItemCanOmitShortcut() {
            let target = StandardMenuTarget()
            let item = SaneStandardMenu.settingsItem(
                target: target,
                action: #selector(StandardMenuTarget.openSettings(_:)),
                keyEquivalent: ""
            )

            #expect(item.title == "Settings...")
            #expect(item.keyEquivalent.isEmpty)
            #expect(item.keyEquivalentModifierMask.isEmpty)
        }

        @Test("Shared footer items use standard titles")
        func sharedFooterItemsUseStandardTitles() {
            let target = StandardMenuTarget()
            let openItem = SaneStandardMenu.openAppItem(
                appName: "SaneClick",
                target: target,
                action: #selector(StandardMenuTarget.openApp(_:))
            )
            let updateItem = SaneStandardMenu.checkForUpdatesItem(
                target: target,
                action: #selector(StandardMenuTarget.checkForUpdates(_:))
            )
            let licenseItem = SaneStandardMenu.licenseItem(
                target: target,
                action: #selector(StandardMenuTarget.license(_:))
            )
            let aboutItem = SaneStandardMenu.aboutAndBugReportItem(
                target: target,
                action: #selector(StandardMenuTarget.about(_:))
            )
            let whatsNewItem = SaneStandardMenu.whatsNewItem(
                target: target,
                action: #selector(StandardMenuTarget.whatsNew(_:))
            )
            let quitItem = SaneStandardMenu.quitItem(
                appName: "SaneClick",
                target: target,
                action: #selector(StandardMenuTarget.quit(_:))
            )

            #expect(openItem.title == "Open SaneClick")
            #expect(updateItem.title == "Check for Updates...")
            #expect(licenseItem.title == "License...")
            #expect(aboutItem.title == "About / Report a Bug...")
            #expect(whatsNewItem.title == "What's New...")
            #expect(updateItem.keyEquivalent.isEmpty)
            #expect(quitItem.title == "Quit SaneClick")
            #expect(quitItem.keyEquivalent == "q")
            #expect(quitItem.keyEquivalentModifierMask.contains(.command))
        }
    }
#endif

@Suite("Shared Gradient Background")
struct SaneGradientBackgroundTests {
    @Test("Panel gradient stays calmer than standard")
    func panelGradientUsesLowerOpacity() {
        #expect(SaneGradientBackground.meshOpacity(for: .panel) < SaneGradientBackground.meshOpacity(for: .standard))
        #expect(SaneGradientBackground.meshOpacity(for: .panel) == 0.9)
        #expect(SaneGradientBackground.meshOpacity(for: .standard) == 1.0)
    }

    @Test("Gradient animation is opt-in and respects reduce motion")
    func gradientAnimationIsOptIn() {
        #expect(!SaneGradientBackground.usesAnimatedMesh(style: .panel, reduceMotion: false))
        #expect(!SaneGradientBackground.usesAnimatedMesh(style: .standard, reduceMotion: false))
        #expect(SaneGradientBackground.usesAnimatedMesh(
            style: .standard,
            reduceMotion: false,
            motion: .animated
        ))
        #expect(!SaneGradientBackground.usesAnimatedMesh(style: .standard, reduceMotion: true))
        #expect(!SaneGradientBackground.usesAnimatedMesh(
            style: .standard,
            reduceMotion: true,
            motion: .animated
        ))
    }
}
