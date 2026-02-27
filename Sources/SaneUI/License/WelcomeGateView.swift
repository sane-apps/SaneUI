import AppKit
import SwiftUI

/// First-install welcome screen with Free vs Pro tier comparison.
/// Shown ONCE on first launch. NOT a blocking gate — user can always dismiss.
///
/// ```swift
/// .sheet(isPresented: $showWelcome) {
///     WelcomeGateView(
///         appName: "SaneClick",
///         appIcon: "cursorarrow.click.2",
///         freeFeatures: [("star.fill", "9 Essential scripts"), ...],
///         proFeatures: [("chevron.left.forwardslash.chevron.right", "All 50+ scripts"), ...],
///         licenseService: licenseService
///     )
/// }
/// ```
public struct WelcomeGateView: View {
    let appName: String
    let appIcon: String
    let freeFeatures: [(icon: String, text: String)]
    let proFeatures: [(icon: String, text: String)]
    @Bindable var licenseService: LicenseService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: Tier = .pro
    @State private var showingLicenseEntry = false

    private enum Tier { case free, pro }

    // Palette matching SaneBar onboarding
    private let cardBg = Color(red: 0.08, green: 0.10, blue: 0.18)

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
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom controls
            HStack {
                Spacer()

                Button {
                    if selectedTier == .pro, !licenseService.isPro {
                        if licenseService.usesAppStorePurchase {
                            Task { await licenseService.purchasePro() }
                            return
                        }
                        if let url = licenseService.checkoutURL { NSWorkspace.shared.open(url) }
                    }
                    dismiss()
                } label: {
                    Text(selectedTier == .pro && !licenseService.isPro
                             ? (licenseService.usesAppStorePurchase ? "Unlock Pro" : "Get Started")
                             : "Start Free")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.large)
                .disabled(licenseService.isPurchasing)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .frame(width: 620, height: 520)
        .background(welcomeBackground)
        .sheet(isPresented: $showingLicenseEntry) {
            LicenseEntryView(licenseService: licenseService)
        }
        .onChange(of: licenseService.isPro) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            }
        }
        .task {
            if licenseService.usesAppStorePurchase {
                await licenseService.preloadAppStoreProduct()
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if licenseService.isPro {
            proActivatedContent
        } else {
            selectionContent
        }
    }

    // MARK: - Already Pro

    private var proActivatedContent: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("Pro Activated")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text("All features unlocked.\nThank you for your support!")
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

    // MARK: - Free vs Pro Selection

    private var selectionContent: some View {
        VStack(spacing: 12) {
            // App icon + welcome text
            if let nsIcon = NSApp.applicationIconImage {
                Image(nsImage: nsIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            } else {
                Image(systemName: appIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(.teal)
            }

            Text("Welcome to \(appName)")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            // Tier cards — Pro first (left), Free second (right)
            HStack(alignment: .top, spacing: 14) {
                tierCard(
                    tier: .pro,
                    title: "Pro — \(licenseService.appStoreDisplayPrice ?? "$6.99")",
                    price: "One-time — yours forever",
                    features: proFeatures,
                    actions: {
                        VStack(spacing: 6) {
                            Button {
                                if licenseService.usesAppStorePurchase {
                                    Task { await licenseService.purchasePro() }
                                } else {
                                    if let url = licenseService.checkoutURL { NSWorkspace.shared.open(url) }
                                    Task.detached {
                                        await EventTracker.log("upsell_clicked_buy", app: appName.lowercased())
                                    }
                                }
                            } label: {
                                Text(licenseService.isPurchasing ? "Processing..." : "Unlock Pro")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.teal)
                            .controlSize(.regular)
                            .disabled(licenseService.isPurchasing)

                            if licenseService.usesAppStorePurchase {
                                Button("Restore Purchases") {
                                    Task { await licenseService.restorePurchases() }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .font(.system(size: 12))
                                .disabled(licenseService.isPurchasing)
                            } else {
                                Button("I Have a Key") {
                                    showingLicenseEntry = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .font(.system(size: 12))
                            }
                        }
                    }
                )

                tierCard(
                    tier: .free,
                    title: "Basic",
                    price: "Free, forever",
                    features: freeFeatures
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 24)
    }

    // MARK: - Tier Card

    @ViewBuilder
    private func tierCard(
        tier: Tier,
        title: String,
        price: String? = nil,
        features: [(icon: String, text: String)],
        actions: (() -> some View)? = nil as (() -> EmptyView)?
    ) -> some View {
        let isSelected = selectedTier == tier
        let isPro = tier == .pro

        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(isPro ? Color.teal : .white)
                    if let price {
                        Text(price)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? (isPro ? Color.teal : .white) : .white.opacity(0.9))
            }

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                    HStack(alignment: .top, spacing: 7) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(isPro ? Color.teal : .white)
                            .frame(width: 14)
                        Text(feature.text)
                            .font(.system(size: 12))
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
                .shadow(color: isSelected ? Color.teal.opacity(0.15) : .clear, radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected
                        ? (isPro ? Color.teal : Color.white.opacity(0.8))
                        : Color.teal.opacity(0.15),
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

    // MARK: - Background

    private var welcomeBackground: some View {
        ZStack {
            VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)

            RadialGradient(
                colors: [Color.teal.opacity(0.12), Color.clear],
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

// MARK: - Welcome Window (standalone for menu bar apps)

/// Creates a standalone NSWindow for the welcome screen.
/// Used by menu bar apps (SaneClip, etc.) that don't have a main WindowGroup.
@MainActor
public enum WelcomeWindow {
    private static var window: NSWindow?
    private static var delegate: WindowDelegate?

    public static func show(
        appName: String,
        appIcon: String,
        freeFeatures: [(icon: String, text: String)],
        proFeatures: [(icon: String, text: String)],
        licenseService: LicenseService,
        onDismiss: @escaping () -> Void = {}
    ) {
        guard window == nil else { return }

        let welcomeView = WelcomeGateView(
            appName: appName,
            appIcon: appIcon,
            freeFeatures: freeFeatures,
            proFeatures: proFeatures,
            licenseService: licenseService
        )

        let hostingView = NSHostingView(rootView: welcomeView)

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 520),
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
        win.center()

        // Clean up static reference when user closes the window
        let windowDelegate = WindowDelegate(onClose: {
            window = nil
            WelcomeWindow.delegate = nil
            onDismiss()
        })
        win.delegate = windowDelegate
        WelcomeWindow.delegate = windowDelegate

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
