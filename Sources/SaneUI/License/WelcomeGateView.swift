import AppKit
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

private enum Tier { case free, pro }

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
    @Bindable var licenseService: LicenseService
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0
    @State private var navigateForward = true
    @State private var selectedTier: Tier = .pro
    @State private var showingLicenseEntry = false
    @State private var accessibilityGranted = AXIsProcessTrusted()

    // Shorter than SaneBar's 8 pages but same format and progression.
    private let totalPages = 6

    public init(
        appName: String,
        appIcon: String,
        freeFeatures: [(icon: String, text: String)],
        proFeatures: [(icon: String, text: String)],
        licenseService: LicenseService
    ) {
        self.appName = appName
        self.appIcon = appIcon
        self.freeFeatures = freeFeatures
        self.proFeatures = proFeatures
        self.licenseService = licenseService
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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            accessibilityGranted = AXIsProcessTrusted()
        }
        .onChange(of: licenseService.isPro) { _, newValue in
            guard newValue else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
            coreFeaturesPage
        case 2:
            proWorkflowPage
        case 3:
            sanePromisePage
        case 4:
            permissionPage
        case 5:
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
                ("app.fill", "Source-app labels and colors help you scan quickly."),
                ("iphone", "Use the iPhone companion with iCloud sync.")
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
        return proFeatures.filter { !$0.text.localizedCaseInsensitiveContains("everything in basic") }
    }

    private var welcomePage: some View {
        VStack(spacing: 20) {
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

            Text("Welcome to \(appName)")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("Your clipboard, finally under control.")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))

            Text("Copy once. Find instantly. Paste cleanly anywhere.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                quickChip(icon: "doc.on.doc", text: "Copy")
                quickChip(icon: "line.3.horizontal.decrease.circle", text: "Find")
                quickChip(icon: "arrow.down.doc", text: "Paste")
            }

            Text("This setup takes under 60 seconds.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(32)
    }

    private var coreFeaturesPage: some View {
        VStack(spacing: 16) {
            (Text("How ").foregroundStyle(.white) + Text(appName).foregroundStyle(saneAccentGradient) + Text(" Works").foregroundStyle(.white))
                .font(.system(size: 28, weight: .bold, design: .serif))

            Text("Daily workflow, in order.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))

            featureCard(
                title: "Core Workflow",
                subtitle: "Capture, find, and paste in seconds",
                features: setupCoreFeatures
            )

            if appName.lowercased() == "saneclip" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Default paste modes")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Original keeps formatting. Plain strips formatting. Smart auto-cleans URLs and code pastes.")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.92))
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
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }

    private var proWorkflowPage: some View {
        VStack(spacing: 16) {
            (Text("Advanced ").foregroundStyle(.white) + Text("Workflow").foregroundStyle(saneAccentGradient) + Text(" Tools").foregroundStyle(.white))
                .font(.system(size: 28, weight: .bold, design: .serif))

            Text("Set once, then copy/paste stays clean and consistent.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))

            featureCard(
                title: "Power Features",
                subtitle: "Automation, privacy, and control",
                features: setupPowerFeatures
            )
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
    }

    // MARK: - Page 4: Sane Promise (matches SaneBar format)

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

            HStack(spacing: 14) {
                PromisePillarCard(
                    icon: "bolt.fill", color: .yellow, title: "Power",
                    lines: ["Your data stays on your device.", "100% transparent code.", "Actively maintained."]
                )
                PromisePillarCard(
                    icon: "heart.fill", color: .red, title: "Love",
                    lines: ["Built to serve you.", "Pay once, yours forever.", "No subscriptions."]
                )
                PromisePillarCard(
                    icon: "brain.head.profile", color: .cyan, title: "Sound Mind",
                    lines: ["Calm and focused.", "Does one thing well.", "No clutter."]
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: - Page 5: Permission

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(saneAccent)

            Text("Grant Access")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                permissionLine(icon: "video.slash.fill", text: "No screen recording.")
                permissionLine(icon: "eye.slash.fill", text: "No screenshots.")
                permissionLine(icon: "icloud.slash", text: "No data collected.")
            }

            if accessibilityGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Permission granted — you're all set!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.green)
                }
                .padding(.top, 8)
            } else {
                Button {
                    openAccessibilitySettings()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 14))
                        Text("Open Accessibility Settings")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 10, horizontalPadding: 18, verticalPadding: 10))

                Text("Toggle \(appName) on in the list that appears")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.92))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Page 6: Basic vs Pro (SaneBar-style close)

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
        VStack(spacing: 10) {
            (Text("Choose").foregroundStyle(saneAccentGradient) + Text(" Your Plan"))
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 14) {
                selectableTierCard(
                    tier: .pro,
                    title: "Pro — \(licenseService.appStoreDisplayPrice ?? "$6.99")",
                    price: "One-time — yours forever",
                    features: proFeatures,
                    actions: {
                        AnyView(VStack(spacing: 6) {
                            Button {
                                if licenseService.usesAppStorePurchase {
                                    Task { await licenseService.purchasePro() }
                                } else if let url = licenseService.checkoutURL {
                                    NSWorkspace.shared.open(url)
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
                            .disabled(licenseService.isPurchasing)

                            if licenseService.usesAppStorePurchase {
                                Button("Restore Purchases") {
                                    Task { await licenseService.restorePurchases() }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .font(.system(size: 13))
                                .disabled(licenseService.isPurchasing)
                            } else {
                                Button("I Have a Key") {
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
                    title: "Basic",
                    price: "$0 forever",
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
                Button(finalPrimaryButtonLabel) {
                    completeOnboarding()
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 10, horizontalPadding: 20, verticalPadding: 9))
                .disabled(licenseService.isPurchasing)
            }
        }
    }

    private var finalPrimaryButtonLabel: String {
        if selectedTier == .pro, !licenseService.isPro {
            return licenseService.usesAppStorePurchase ? "Unlock Pro" : "Get Started"
        }
        return "Start Free"
    }

    private func completeOnboarding() {
        if selectedTier == .pro, !licenseService.isPro {
            if licenseService.usesAppStorePurchase {
                Task { await licenseService.purchasePro() }
                return
            }
            if let url = licenseService.checkoutURL {
                NSWorkspace.shared.open(url)
                Task.detached {
                    await EventTracker.log("upsell_clicked_buy", app: appName.lowercased())
                }
            }
        }
        dismiss()
    }

    // MARK: - Shared UI Helpers

    private func quickChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(saneAccent.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func featureCard(title: String, subtitle: String, features: [(icon: String, text: String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(saneAccentSoft)
                        .frame(width: 14)
                    Text(feature.text)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
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

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
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
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.green)
                            .frame(width: 12)
                            .padding(.top, 2)
                        Text(line)
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
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
