@testable import SaneUI
import Testing

@Suite("License product matching")
struct LicenseProductMatchingTests {
    private let everythingBundle = "SaneApps Everything Bundle"

    @Test(
        "Everything Bundle unlocks each included direct app",
        arguments: ["SaneClick", "SaneClip", "SaneHosts", "SaneSales", "SaneVideo"]
    )
    @MainActor
    func everythingBundleMatchesIncludedApp(appName: String) {
        #expect(LicenseService.licenseProductMatchesApp(
            appName: appName,
            productName: everythingBundle,
            variantName: nil
        ))
    }

    @Test(
        "Everything Bundle rejects apps outside the allowlist",
        arguments: ["SaneBar", "SaneScan", "UnrelatedApp", ""]
    )
    @MainActor
    func everythingBundleRejectsExcludedApp(appName: String) {
        #expect(!LicenseService.licenseProductMatchesApp(
            appName: appName,
            productName: everythingBundle,
            variantName: nil
        ))
    }

    @Test("Everything Bundle in variant metadata uses the same allowlist")
    @MainActor
    func everythingBundleVariantUsesAllowlist() {
        #expect(LicenseService.licenseProductMatchesApp(
            appName: "SaneClip",
            productName: nil,
            variantName: everythingBundle
        ))
        #expect(!LicenseService.licenseProductMatchesApp(
            appName: "SaneBar",
            productName: nil,
            variantName: everythingBundle
        ))
    }

    @Test("Normal product matching remains app-specific")
    @MainActor
    func normalProductMatchingRemainsAppSpecific() {
        #expect(LicenseService.licenseProductMatchesApp(
            appName: "SaneClip",
            productName: "SaneClip",
            variantName: "Pro"
        ))
        #expect(LicenseService.licenseProductMatchesApp(
            appName: "SaneClip",
            productName: "Utility License",
            variantName: "SaneClip Pro"
        ))
        #expect(!LicenseService.licenseProductMatchesApp(
            appName: "SaneClip",
            productName: "SaneHosts",
            variantName: "Pro"
        ))
        #expect(!LicenseService.licenseProductMatchesApp(
            appName: "SaneClip",
            productName: nil,
            variantName: nil
        ))
    }
}
