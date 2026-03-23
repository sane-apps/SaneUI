import SwiftUI

// Onboarding palette and controls aligned with SaneBar.
private let cardBg = Color(red: 0.08, green: 0.10, blue: 0.18)
private let saneAccentDeep = Color.saneAccentDeep
private let saneAccent = Color.saneAccent
private let saneAccentSoft = Color.saneAccentSoft
private let saneAccentGradient = LinearGradient(
    colors: [saneAccentSoft, saneAccent],
    startPoint: .leading,
    endPoint: .trailing
)
private let saneButtonGradient = LinearGradient(
    colors: [saneAccentSoft.opacity(0.98), saneAccent.opacity(0.98)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
private let goldenRatio: CGFloat = 1.618
private let goldenBase: CGFloat = 13
private let goldenGap: CGFloat = goldenBase
private let goldenPad: CGFloat = goldenBase * goldenRatio

enum Tier { case free, pro }
enum WelcomeGatePrimaryAction {
    case complete
    case purchasePro
    case openCheckout
}

public struct WelcomeGatePermissionConfig {
    public let title: String
    public let bullets: [(icon: String, text: String)]
    public let grantedMessage: String?
    public let actionLabel: String?
    public let actionHint: String?
    public let initiallyGranted: Bool
    public let refreshGranted: (() -> Bool)?
    public let action: (() -> Void)?

    public init(
        title: String,
        bullets: [(icon: String, text: String)],
        grantedMessage: String? = nil,
        actionLabel: String? = nil,
        actionHint: String? = nil,
        initiallyGranted: Bool = false,
        refreshGranted: (() -> Bool)? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.bullets = bullets
        self.grantedMessage = grantedMessage
        self.actionLabel = actionLabel
        self.actionHint = actionHint
        self.initiallyGranted = initiallyGranted
        self.refreshGranted = refreshGranted
        self.action = action
    }
}

enum WelcomeGateFlowPolicy {
    static func finalPrimaryAction(
        isPro: Bool,
        selectedTier: Tier,
        channel: SaneDistributionChannel
    ) -> WelcomeGatePrimaryAction {
        guard !isPro else { return .complete }
        guard selectedTier == .pro else { return .complete }
        switch channel {
        case .appStore:
            return .purchasePro
        case .direct:
            return .openCheckout
        case .setapp:
            return .complete
        }
    }

    static func finalPrimaryAction(
        isPro: Bool,
        selectedTier: Tier,
        usesAppStorePurchase: Bool
    ) -> WelcomeGatePrimaryAction {
        finalPrimaryAction(
            isPro: isPro,
            selectedTier: selectedTier,
            channel: usesAppStorePurchase ? .appStore : .direct
        )
    }

    static func finalPrimaryButtonLabel(
        isPro: Bool,
        selectedTier: Tier,
        channel: SaneDistributionChannel
    ) -> String {
        switch finalPrimaryAction(isPro: isPro, selectedTier: selectedTier, channel: channel) {
        case .purchasePro:
            return "Unlock Pro"
        case .openCheckout, .complete:
            return "Get Started"
        }
    }

    static func finalPrimaryButtonLabel(
        isPro: Bool,
        selectedTier: Tier,
        usesAppStorePurchase: Bool
    ) -> String {
        finalPrimaryButtonLabel(
            isPro: isPro,
            selectedTier: selectedTier,
            channel: usesAppStorePurchase ? .appStore : .direct
        )
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat

    init(cornerRadius: CGFloat = 9, horizontalPadding: CGFloat = 16, verticalPadding: CGFloat = 8) {
        self.cornerRadius = cornerRadius
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(saneButtonGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.9)
            )
            .shadow(
                color: saneAccentDeep.opacity(configuration.isPressed ? 0.20 : 0.30),
                radius: configuration.isPressed ? 3 : 8,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// First-install onboarding flow with Free vs Pro comparison.
/// Shown once on first launch.
public struct WelcomeGateView: View {
    let appName: String
    let appIcon: String
    let freeFeatures: [(icon: String, text: String)]
    let proFeatures: [(icon: String, text: String)]
    let freeTierTitle: String
    let freeTierPrice: String?
    let proTierTitleOverride: String?
    let proTierPriceOverride: String?
    let permissionConfig: WelcomeGatePermissionConfig
    @Bindable var licenseService: LicenseService
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var navigateForward = true
    @State private var selectedTier: Tier = .pro
    @State private var showingLicenseEntry = false
    @State private var permissionGranted = false
    private let autoDismissOnPro: Bool
    private let secondaryCompletionActionLabel: String?
    private let secondaryCompletionAccessibilityIdentifier: String?
    private let onSecondaryCompletion: (() -> Void)?
    private let onComplete: (() -> Void)?

    // Canonical onboarding flow across all apps.
    private static let pageCount = 7
    private let totalPages = Self.pageCount

    public init(
        appName: String,
        appIcon: String,
        freeFeatures: [(icon: String, text: String)],
        proFeatures: [(icon: String, text: String)],
        freeTierTitle: String = "Basic",
        freeTierPrice: String? = "$0 forever",
        proTierTitleOverride: String? = nil,
        proTierPriceOverride: String? = nil,
        permissionConfig: WelcomeGatePermissionConfig? = nil,
        licenseService: LicenseService,
        initialPage: Int = 0,
        autoDismissOnPro: Bool = true,
        secondaryCompletionActionLabel: String? = nil,
        secondaryCompletionAccessibilityIdentifier: String? = nil,
        onSecondaryCompletion: (() -> Void)? = nil,
        onComplete: (() -> Void)? = nil
    ) {
        self.appName = appName
        self.appIcon = appIcon
        self.freeFeatures = freeFeatures
        self.proFeatures = proFeatures
        self.freeTierTitle = freeTierTitle
        self.freeTierPrice = freeTierPrice
        self.proTierTitleOverride = proTierTitleOverride
        self.proTierPriceOverride = proTierPriceOverride
        self.permissionConfig = permissionConfig ?? WelcomeGatePermissionConfig(
            title: "Privacy First",
            bullets: [
                ("video.slash.fill", "No screen recording."),
                ("eye.slash.fill", "No screenshots."),
                ("icloud.slash", "No data collected.")
            ],
            grantedMessage: "You're all set. No extra setup is required here."
        )
        self.licenseService = licenseService
        self.autoDismissOnPro = autoDismissOnPro
        self.secondaryCompletionActionLabel = secondaryCompletionActionLabel
        self.secondaryCompletionAccessibilityIdentifier = secondaryCompletionAccessibilityIdentifier
        self.onSecondaryCompletion = onSecondaryCompletion
        self.onComplete = onComplete
        _currentPage = State(initialValue: max(0, min(initialPage, Self.pageCount - 1)))
        _permissionGranted = State(initialValue: self.permissionConfig.initiallyGranted)
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                pageContent
                    .id(currentPage)
                    .transition(.asymmetric(
                        insertion: .move(edge: navigateForward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: navigateForward ? .leading : .trailing).combined(with: .opacity)
                    ))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            HStack(spacing: 4) {
                ForEach(0 ..< totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? saneAccent : Color.white.opacity(0.15))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 16)

            bottomControls
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
        }
        .frame(width: 700, height: 520)
        .background(onboardingBackground)
        .sheet(isPresented: $showingLicenseEntry) {
            LicenseEntryView(licenseService: licenseService)
        }
        .onReceive(NotificationCenter.default.publisher(for: SanePlatform.didBecomeActiveNotification)) { _ in
            guard let refreshGranted = permissionConfig.refreshGranted else { return }
            permissionGranted = refreshGranted()
        }
        .onChange(of: licenseService.isPro) { _, newValue in
            guard autoDismissOnPro, newValue else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onComplete?()
                dismiss()
            }
        }
        .task {
            if licenseService.usesAppStorePurchase {
                await licenseService.preloadAppStoreProduct()
            }
        }
    }

    // MARK: - Content Pages

    @ViewBuilder
    private var pageContent: some View {
        switch currentPage {
        case 0:
            welcomePage
        case 1:
            dontSkipPage
        case 2:
            coreFeaturesPage
        case 3:
            proWorkflowPage
        case 4:
            sanePromisePage
        case 5:
            permissionPage
        case 6:
            finalTierPage
        default:
            welcomePage
        }
    }

    private var setupCoreFeatures: [(icon: String, text: String)] {
        if appName.lowercased() == "saneclip" {
            return [
                ("doc.on.doc", "Every copy is saved to your clipboard history."),
                ("magnifyingglass", "Search by content, source app, or date."),
                ("keyboard", "Use hotkeys: Cmd+Shift+V opens history, Cmd+Control+1-9 pastes fast."),
                ("cursorarrow.motionlines", "Choose where history opens: menu bar icon or mouse cursor."),
                ("app.fill", "Source-app labels and colors help you scan quickly."),
                ("iphone", "Use the iPhone companion with iCloud sync.")
            ]
        }
        if appSlug == "sanehosts" {
            return [
                ("shield.checkered", "Choose your protection level."),
                ("checkmark.circle.fill", "Click Activate once."),
                ("gearshape.2.fill", "SaneHosts safely updates your hosts file."),
                ("bolt.horizontal.circle", "System-wide blocking starts immediately.")
            ]
        }
        return freeFeatures
    }

    private var setupPowerFeatures: [(icon: String, text: String)] {
        if appName.lowercased() == "saneclip" {
            return [
                ("wand.and.stars", "Smart paste cleans tracking URLs and handles code safely."),
                ("textformat", "Transform text while pasting: upper, lower, title, trimmed, and more."),
                ("square.stack.3d.up", "Queue clips in Paste Stack and paste FIFO or LIFO."),
                ("text.quote", "Save snippets with placeholders like {{date}}, {{time}}, and {{clipboard}}."),
                ("ruler", "Apply clipboard rules: strip trackers, trim whitespace, normalize text."),
                ("lock.shield.fill", "Protect history at rest with AES-256-GCM encryption."),
                ("exclamationmark.shield.fill", "Detect sensitive data and auto-purge on your schedule."),
                ("arrow.up.arrow.down.circle", "Export and import history when moving devices or backing up."),
                ("link.badge.plus", "Use Integrations, Shortcuts, and webhooks for automation.")
            ]
        }
        if appSlug == "sanehosts" {
            return [
                ("doc.on.doc", "Create multiple profiles for different environments."),
                ("arrow.down.circle", "Install downloadable presets in one click."),
                ("arrow.triangle.merge", "Merge profiles into a single ruleset."),
                ("checklist", "Run bulk operations across large entry sets."),
                ("square.and.arrow.down", "Import profiles from files or URLs.")
            ]
        }
        return proFeatures.filter { !$0.text.localizedCaseInsensitiveContains("everything in basic") }
    }

    private var appSlug: String {
        appName.lowercased().replacingOccurrences(of: " ", with: "")
    }

    private var welcomeSummary: String {
        switch appSlug {
        case "sanehosts":
            return "Block ads, trackers, malware, and distractions system-wide on your Mac."
        case "saneclick":
            return "Run useful Finder actions from right-click, without leaving your workflow."
        case "sanesales":
            return "Track revenue, orders, and trends across your sales platforms in one place."
        case "saneclip":
            return "Save everything you copy, find it instantly, and paste cleaner."
        case "sanebar":
            return "Take control of your menu bar so your Mac stays clean and focused."
        default:
            return "A calm setup to get productive fast."
        }
    }

    private var setupGuidance: String {
        switch appSlug {
        case "sanehosts":
            return "Pick, Click, Protected."
        case "saneclick":
            return "In under 60 seconds: enable Finder extension, pick scripts, then right-click to run."
        case "sanesales":
            return "In under 60 seconds: connect data sources, review dashboard, then monitor in real time."
        case "saneclip":
            return "In under 60 seconds: confirm permissions, choose plan, then start copying."
        default:
            return "This takes about a minute. Follow each step in order."
        }
    }

    private var welcomeChips: [(icon: String, text: String)] {
        switch appSlug {
        case "sanehosts":
            return [("checkmark.seal", "Choose Profile"), ("shield.checkered", "Activate"), ("arrow.right.circle", "Done")]
        case "saneclick":
            return [("checkmark.seal", "Enable"), ("cursorarrow.click.2", "Right-Click"), ("arrow.right.circle", "Run")]
        case "sanesales":
            return [("checkmark.seal", "Connect"), ("chart.xyaxis.line", "Review"), ("arrow.right.circle", "Track")]
        default:
            return [("checkmark.seal", "Set Up"), ("sparkles", "Learn"), ("arrow.right.circle", "Launch")]
        }
    }

    private var welcomeHighlights: [(icon: String, text: String)] {
        if appSlug == "sanehosts" {
            return []
        }
        return Array(freeFeatures.prefix(3))
    }

    private var coreLeadText: String {
        switch appSlug {
        case "sanehosts":
            return "Basic setup once, then protection runs quietly in the background."
        default:
            return "Daily workflow, in order."
        }
    }

    private var coreCardTitle: String {
        appSlug == "sanehosts" ? "Basic Setup" : "Core Workflow"
    }

    private var coreCardSubtitle: String {
        switch appSlug {
        case "sanehosts":
            return "One-click protection: choose level, activate, done"
        default:
            return "Capture, find, and paste in seconds"
        }
    }

    private var proLeadText: String {
        switch appSlug {
        case "sanehosts":
            return "Advanced features for power users who need deeper control."
        default:
            return "Set once, then copy/paste stays clean and consistent."
        }
    }

    private var proCardTitle: String {
        appSlug == "sanehosts" ? "Advanced Features" : "Power Features"
    }

    private var proCardSubtitle: String {
        switch appSlug {
        case "sanehosts":
            return "Profiles, presets, merge, import, and bulk tools"
        default:
            return "Automation, privacy, and control"
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
            #if os(macOS)
                if let nsIcon = NSApp.applicationIconImage {
                    Image(nsImage: nsIcon)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                } else {
                    Image(systemName: appIcon)
                        .font(.system(size: 56))
                        .foregroundStyle(saneAccentSoft)
                }
            #else
                Image(systemName: appIcon)
                    .font(.system(size: 56))
                    .foregroundStyle(saneAccentSoft)
            #endif

            Text("Welcome to \(appName)")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text(welcomeSummary)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(setupGuidance)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                ForEach(Array(welcomeChips.enumerated()), id: \.offset) { _, chip in
                    quickChip(icon: chip.icon, text: chip.text, accented: appSlug == "sanehosts")
                }
            }

            if !welcomeHighlights.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(welcomeHighlights.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: item.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(saneAccentSoft)
                                .frame(width: 14)
                            Text(item.text)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
            }

            Text("This setup takes under 60 seconds.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(32)
    }

    private var dontSkipPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.wave.fill")
                .font(.system(size: 48))
                .foregroundStyle(saneAccent)

            Text("Don't skip this.")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("It's only a few screens and you'll be\nconfused if you rush through.")
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("— Mr. Sane")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var coreFeaturesPage: some View {
        if appSlug == "sanehosts" {
            saneHostsCorePage
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: goldenGap) {
                    VStack(spacing: goldenBase * 0.62) {
                        (Text("How ").foregroundStyle(.white) + Text(appName).foregroundStyle(saneAccentGradient) + Text(" Works").foregroundStyle(.white))
                            .font(.system(size: 30, weight: .bold, design: .serif))

                        Text(coreLeadText)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, goldenBase * 0.35)

                    VStack(spacing: goldenBase * 0.62) {
                        featureCard(
                            title: coreCardTitle,
                            subtitle: coreCardSubtitle,
                            features: setupCoreFeatures,
                            columns: 1,
                            compact: false
                        )

                        if appName.lowercased() == "saneclip" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Default paste modes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Original keeps formatting. Plain strips formatting. Smart auto-cleans URLs and code pastes.")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white.opacity(0.95))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(saneAccent.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, goldenPad)
                .padding(.top, goldenBase)
                .padding(.bottom, goldenBase * 1.4)
            }
        }
    }

    @ViewBuilder
    private var proWorkflowPage: some View {
        if appSlug == "sanehosts" {
            saneHostsAdvancedPage
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: goldenGap) {
                    VStack(spacing: goldenBase * 0.62) {
                        (Text("Advanced ").foregroundStyle(.white) + Text("Workflow").foregroundStyle(saneAccentGradient) + Text(" Tools").foregroundStyle(.white))
                            .font(.system(size: 30, weight: .bold, design: .serif))

                        Text(proLeadText)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, goldenBase * 0.35)

                    featureCard(
                        title: proCardTitle,
                        subtitle: proCardSubtitle,
                        features: setupPowerFeatures,
                        columns: 1,
                        compact: false
                    )
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.horizontal, goldenPad)
                .padding(.top, goldenBase)
                .padding(.bottom, goldenBase * 1.4)
            }
        }
    }

    private var saneHostsCorePage: some View {
        VStack(spacing: goldenBase * 1.2) {
            VStack(spacing: goldenBase * 0.62) {
                (Text("How ").foregroundStyle(.white) + Text("SaneHosts").foregroundStyle(saneAccentGradient) + Text(" Works").foregroundStyle(.white))
                    .font(.system(size: 30, weight: .bold, design: .serif))

                Text("One click, then you're protected.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .top, spacing: 13) {
                onboardingStepCard(
                    title: "Setup",
                    rows: [
                        ("1", "Choose protection level"),
                        ("2", "Click Enable Protection"),
                        ("3", "Done")
                    ]
                )
                .frame(width: 250)

                onboardingResultCard(
                    title: "After you enable",
                    bullets: [
                        "System-wide blocking starts",
                        "Hosts file updates safely",
                        "DNS cache flushes automatically"
                    ]
                )
                .frame(width: 250)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.horizontal, goldenPad)
        .padding(.vertical, goldenBase)
    }

    private var saneHostsAdvancedPage: some View {
        VStack(spacing: goldenBase * 1.2) {
            VStack(spacing: goldenBase * 0.62) {
                (Text("Advanced ").foregroundStyle(.white) + Text("Features").foregroundStyle(saneAccentGradient))
                    .font(.system(size: 30, weight: .bold, design: .serif))

                Text("More control when you need it.")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: goldenGap), GridItem(.flexible(), spacing: goldenGap)], spacing: goldenGap) {
                advancedFeatureTile(
                    title: "Multiple Profiles",
                    subtitle: "Create separate setups for different needs."
                )
                advancedFeatureTile(
                    title: "Downloadable Presets",
                    subtitle: "Install curated blocklists in one click."
                )
                advancedFeatureTile(
                    title: "Merge Profiles",
                    subtitle: "Combine rule sets into one unified profile."
                )
                advancedFeatureTile(
                    title: "Import from File / URL",
                    subtitle: "Bring in external sources quickly."
                )
            }
        }
        .padding(.horizontal, goldenPad)
        .padding(.vertical, goldenBase)
    }

    // MARK: - Page 5: Sane Philosophy

    private var sanePromisePage: some View {
        VStack(spacing: 20) {
            Text("Our Sane Philosophy")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            VStack(spacing: 6) {
                Text("\"For God has not given us a spirit of fear,")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.white)
                Text("but of power and of love and of a sound mind.\"")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.white)
                Text("— 2 Timothy 1:7")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(spacing: goldenBase) {
                PromisePillarCard(
                    icon: "bolt.fill", color: .yellow, title: "Power",
                    lines: ["Your data stays on your device.", "100% transparent code.", "Actively maintained."]
                )
                PromisePillarCard(
                    icon: "heart.fill", color: .red, title: "Love",
                    lines: ["Built to serve you.", "Pay once, yours forever.", "No subscriptions. No ads."]
                )
                PromisePillarCard(
                    icon: "brain.head.profile", color: .cyan, title: "Sound Mind",
                    lines: ["Calm and focused.", "Does one thing well.", "No clutter."]
                )
            }
            .padding(.horizontal, goldenBase)
            .padding(.top, 4)
        }
        .padding(.horizontal, goldenPad)
        .padding(.vertical, goldenBase)
    }

    // MARK: - Page 6: Permissions

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(saneAccent)

            Text(permissionConfig.title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(permissionConfig.bullets.enumerated()), id: \.offset) { _, bullet in
                    permissionLine(icon: bullet.icon, text: bullet.text)
                }
            }

            if permissionGranted, let grantedMessage = permissionConfig.grantedMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(grantedMessage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.green)
                }
                .padding(.top, 8)
            } else if let actionLabel = permissionConfig.actionLabel,
                      let action = permissionConfig.action {
                Button {
                    action()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 14))
                        Text(actionLabel)
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 10, horizontalPadding: 18, verticalPadding: 10))

                if let actionHint = permissionConfig.actionHint {
                    Text(actionHint)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.92))
                }
            } else if let grantedMessage = permissionConfig.grantedMessage {
                Text(grantedMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Page 7: Plan / Upgrade

    @ViewBuilder
    private var finalTierPage: some View {
        if licenseService.isPro {
            proActivatedView
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
        } else {
            selectionView
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
        }
    }

    private var proActivatedView: some View {
        VStack(spacing: 10) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("Pro Activated")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("All features unlocked.\nI couldn't do this without you.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("— Mr. Sane")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 2)

            Spacer()
        }
    }

    private var selectionView: some View {
        let resolvedProTitle = proTierTitleOverride
            ?? (licenseService.usesSetappPurchase ? "Pro — Setapp" : "Pro — \(licenseService.appStoreDisplayPrice ?? "$6.99")")
        let resolvedProPrice = proTierPriceOverride
            ?? (licenseService.usesSetappPurchase ? "Included with your Setapp install" : "One-time — yours forever")

        VStack(spacing: 10) {
            (Text("Choose").foregroundStyle(saneAccentGradient) + Text(" Your Plan"))
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 14) {
                selectableTierCard(
                    tier: .pro,
                    title: resolvedProTitle,
                    price: resolvedProPrice,
                    features: proFeatures,
                    actions: {
                        AnyView(VStack(spacing: 6) {
                            Button {
                                if licenseService.usesAppStorePurchase {
                                    Task { await licenseService.purchasePro() }
                                } else if licenseService.usesSetappPurchase {
                                    return
                                } else if let url = licenseService.checkoutURL {
                                    SanePlatform.open(url)
                                    Task.detached {
                                        await EventTracker.log("upsell_clicked_buy", app: appName.lowercased())
                                    }
                                }
                            } label: {
                                Text(licenseService.isPurchasing ? "Processing..." : "Unlock Pro")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 9, horizontalPadding: 14, verticalPadding: 7))
                            .disabled(licenseService.isPurchasing || licenseService.usesSetappPurchase)

                            if licenseService.usesAppStorePurchase {
                                Button("Restore Purchases") {
                                    Task { await licenseService.restorePurchases() }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .font(.system(size: 13))
                                .disabled(licenseService.isPurchasing)
                            } else if licenseService.usesSetappPurchase {
                                Text("Managed by Setapp")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.82))
                            } else {
                                Button(licenseService.alternateUnlockLabel) {
                                    showingLicenseEntry = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                    .font(.system(size: 13))
                            }
                        })
                    }
                )

                selectableTierCard(
                    tier: .free,
                    title: freeTierTitle,
                    price: freeTierPrice,
                    features: freeFeatures
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func selectableTierCard(
        tier: Tier,
        title: String,
        price: String? = nil,
        features: [(icon: String, text: String)],
        actions: (() -> AnyView)? = nil
    ) -> some View {
        let isSelected = selectedTier == tier
        let isPro = tier == .pro

        return VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isPro ? saneAccentSoft : .white)
                    if let price {
                        Text(price)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? (isPro ? saneAccentSoft : .white) : .white.opacity(0.9))
            }

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 13))
                            .foregroundStyle(isPro ? saneAccentSoft : .white)
                            .frame(width: 14)
                        Text(feature.text)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let actions {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 0.5)
                    .padding(.top, 4)

                actions()
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .shadow(color: isSelected ? saneAccent.opacity(0.18) : .clear, radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected
                        ? (isPro ? saneAccentSoft : Color.white.opacity(0.8))
                        : saneAccent.opacity(0.2),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTier = tier
            }
        }
    }

    // MARK: - Controls

    private var bottomControls: some View {
        HStack {
            if currentPage > 0 {
                Button("Back") {
                    navigateForward = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage -= 1
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.92))
                .font(.system(size: 14))
            }

            Spacer()

            if currentPage < totalPages - 1 {
                Button("Next") {
                    navigateForward = true
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle())
            } else {
                HStack(spacing: 10) {
                    if let secondaryCompletionActionLabel {
                        Button(secondaryCompletionActionLabel) {
                            completeOnboarding(useSecondaryAction: true)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .font(.system(size: 14, weight: .medium))
                        .disabled(licenseService.isPurchasing)
                        .accessibilityIdentifier(secondaryCompletionAccessibilityIdentifier ?? "")
                    }

                    Button(finalPrimaryButtonLabel) {
                        completeOnboarding()
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 10, horizontalPadding: 20, verticalPadding: 9))
                    .disabled(licenseService.isPurchasing)
                }
            }
        }
    }

    private var finalPrimaryButtonLabel: String {
        WelcomeGateFlowPolicy.finalPrimaryButtonLabel(
            isPro: licenseService.isPro,
            selectedTier: selectedTier,
            channel: licenseService.distributionChannel
        )
    }

    private func completeOnboarding(useSecondaryAction: Bool = false) {
        if useSecondaryAction {
            onSecondaryCompletion?()
            onComplete?()
            dismiss()
            return
        }

        switch WelcomeGateFlowPolicy.finalPrimaryAction(
            isPro: licenseService.isPro,
            selectedTier: selectedTier,
            channel: licenseService.distributionChannel
        ) {
        case .purchasePro:
            if licenseService.usesAppStorePurchase {
                Task { await licenseService.purchasePro() }
                return
            }
        case .openCheckout:
            if let url = licenseService.checkoutURL {
                SanePlatform.open(url)
                Task.detached {
                    await EventTracker.log("upsell_clicked_buy", app: appName.lowercased())
                }
            }
        case .complete:
            break
        }
        onComplete?()
        dismiss()
    }

    // MARK: - Shared UI Helpers

    private func onboardingStepCard(
        title: String,
        rows: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            gradientLeadingWordText(title)
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(alignment: .top, spacing: 8) {
                        Text(row.0)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 17, height: 17)
                            .background(
                                Circle()
                                    .fill(saneAccentDeep.opacity(0.8))
                                    .overlay(
                                        Circle()
                                            .stroke(saneAccent.opacity(0.7), lineWidth: 1)
                                    )
                            )
                        Text(row.1)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(saneAccent.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: saneAccentDeep.opacity(0.16), radius: 8, x: 0, y: 3)
        )
    }

    private func onboardingResultCard(
        title: String,
        bullets: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            gradientLeadingWordText(title)
                .font(.system(size: 16, weight: .semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(bullets.enumerated()), id: \.offset) { _, bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(saneAccentSoft)
                            .frame(width: 5, height: 5)
                            .padding(.top, 5)
                        Text(bullet)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(saneAccentSoft)
                Text("Protection status updates in real time.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(saneAccent.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: saneAccentDeep.opacity(0.16), radius: 8, x: 0, y: 3)
        )
    }

    private func gradientLeadingWordText(_ title: String) -> Text {
        let parts = title.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count == 2 {
            return Text(String(parts[0])).foregroundStyle(saneAccentGradient) + Text(" \(parts[1])").foregroundStyle(.white)
        }
        return Text(title).foregroundStyle(saneAccentGradient)
    }

    private func advancedFeatureTile(
        title: String,
        subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(saneAccentSoft)
                gradientLeadingWordText(title)
                    .font(.system(size: 16, weight: .semibold))
            }

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 98, alignment: .topLeading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(saneAccent.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: saneAccentDeep.opacity(0.14), radius: 6, x: 0, y: 2)
        )
    }

    private func quickChip(icon: String, text: String, accented: Bool = false) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(accented ? saneAccentSoft : .white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(accented ? saneAccentDeep.opacity(0.4) : cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(accented ? saneAccent.opacity(0.55) : saneAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func featureCard(
        title: String,
        subtitle: String,
        features: [(icon: String, text: String)],
        columns: Int = 1,
        compact: Bool = true
    ) -> some View {
        let titleSize: CGFloat = compact ? 16 : 19
        let subtitleSize: CGFloat = compact ? 12 : 15
        let bodySize: CGFloat = compact ? 13 : 16
        let iconSize: CGFloat = compact ? 12 : 14
        let rowSpacing: CGFloat = compact ? 8 : 12

        return VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: titleSize, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: subtitleSize, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            if columns <= 1 {
                ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                    HStack(alignment: .top, spacing: rowSpacing) {
                        Image(systemName: feature.icon)
                            .font(.system(size: iconSize, weight: .semibold))
                            .foregroundStyle(saneAccentSoft)
                            .frame(width: compact ? 14 : 16)
                        Text(feature.text)
                            .font(.system(size: bodySize, weight: .medium))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                let chunkSize = max(1, (features.count + columns - 1) / columns)
                HStack(alignment: .top, spacing: compact ? 18 : 24) {
                    ForEach(0 ..< columns, id: \.self) { col in
                        VStack(alignment: .leading, spacing: rowSpacing) {
                            ForEach(Array(features.dropFirst(col * chunkSize).prefix(chunkSize).enumerated()), id: \.offset) { _, feature in
                                HStack(alignment: .top, spacing: rowSpacing) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: iconSize, weight: .semibold))
                                        .foregroundStyle(saneAccentSoft)
                                        .frame(width: compact ? 14 : 16)
                                    Text(feature.text)
                                        .font(.system(size: bodySize, weight: .medium))
                                        .foregroundStyle(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 14 : 18)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(saneAccent.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: saneAccentDeep.opacity(0.16), radius: 8, x: 0, y: 3)
        )
    }

    private func permissionLine(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(saneAccent)
                .frame(width: 28)
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private var onboardingBackground: some View {
        ZStack {
            SaneGradientBackground()

            RadialGradient(
                colors: [saneAccentDeep.opacity(0.14), Color.clear],
                center: .top,
                startRadius: 50,
                endRadius: 400
            )

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.06),
                    Color.indigo.opacity(0.04),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct PromisePillarCard: View {
    let icon: String
    let color: Color
    let title: String
    let lines: [String]

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.green)
                            .frame(width: 12)
                            .padding(.top, 2)
                        Text(line)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 188, alignment: .top)
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(saneAccent.opacity(0.24), lineWidth: 1)
                )
                .shadow(color: saneAccentDeep.opacity(0.16), radius: 8, x: 0, y: 3)
        )
    }
}

// MARK: - Welcome Window (standalone for menu bar apps)

/// Creates a standalone NSWindow for the welcome screen.
/// Used by menu bar apps (SaneClip, etc.) that don't have a main WindowGroup.
#if os(macOS)
@MainActor
public enum WelcomeWindow {
    private static var window: NSWindow?
    private static var delegate: WindowDelegate?
    private static var priorActivationPolicy: NSApplication.ActivationPolicy?

    public static func show(
        appName: String,
        appIcon: String,
        freeFeatures: [(icon: String, text: String)],
        proFeatures: [(icon: String, text: String)],
        permissionConfig: WelcomeGatePermissionConfig? = nil,
        licenseService: LicenseService,
        onDismiss: @escaping () -> Void = {}
    ) {
        if let existingWindow = window {
            if existingWindow.isMiniaturized {
                existingWindow.deminiaturize(nil)
            }
            existingWindow.collectionBehavior = existingWindow.collectionBehavior.union([.moveToActiveSpace])
            existingWindow.orderFrontRegardless()
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        if NSApp.activationPolicy() != .regular {
            priorActivationPolicy = NSApp.activationPolicy()
            NSApp.setActivationPolicy(.regular)
        }

        NSApp.activate(ignoringOtherApps: true)

        let welcomeView = WelcomeGateView(
            appName: appName,
            appIcon: appIcon,
            freeFeatures: freeFeatures,
            proFeatures: proFeatures,
            permissionConfig: permissionConfig,
            licenseService: licenseService
        )

        let hostingView = NSHostingView(rootView: welcomeView)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.contentView = hostingView
        win.appearance = NSAppearance(named: .darkAqua)
        win.title = "Welcome to \(appName)"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.backgroundColor = .windowBackgroundColor
        win.isReleasedWhenClosed = false
        win.collectionBehavior = win.collectionBehavior.union([.moveToActiveSpace])
        win.center()

        let windowDelegate = WindowDelegate(onClose: {
            window = nil
            WelcomeWindow.delegate = nil
            if let priorPolicy = priorActivationPolicy {
                NSApp.setActivationPolicy(priorPolicy)
                priorActivationPolicy = nil
            }
            onDismiss()
        })
        win.delegate = windowDelegate
        WelcomeWindow.delegate = windowDelegate

        win.orderFrontRegardless()
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = win
    }

    public static func close() {
        window?.close()
        window = nil
        delegate = nil
    }

    private final class WindowDelegate: NSObject, NSWindowDelegate, @unchecked Sendable {
        let onClose: () -> Void
        init(onClose: @escaping () -> Void) { self.onClose = onClose }
        func windowWillClose(_: Notification) {
            DispatchQueue.main.async { self.onClose() }
        }
    }
}
#endif
