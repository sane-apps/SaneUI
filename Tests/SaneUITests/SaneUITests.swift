import Testing
@testable import SaneUI

@Suite("Welcome Gate Flow Policy")
struct WelcomeGateFlowPolicyTests {
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
}

@Suite("Sane App Mover")
struct SaneAppMoverTests {
    @Test("Treats /Applications as installed")
    func systemApplicationsPathIsInstalled() {
        #expect(SaneAppMover.isInApplicationsDirectory("/Applications/SaneBar.app", homeDirectory: "/Users/tester"))
    }

    @Test("Treats ~/Applications as installed")
    func userApplicationsPathIsInstalled() {
        #expect(SaneAppMover.isInApplicationsDirectory("/Users/tester/Applications/SaneBar.app", homeDirectory: "/Users/tester"))
    }

    @Test("Treats Downloads as not installed")
    func downloadsPathIsNotInstalled() {
        #expect(!SaneAppMover.isInApplicationsDirectory("/Users/tester/Downloads/SaneBar.app", homeDirectory: "/Users/tester"))
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
