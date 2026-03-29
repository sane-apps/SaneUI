import AppKit
import SaneUI
import SwiftUI

private enum CatalogTab: String, SaneSettingsTab {
    case foundations = "Foundations"
    case controls = "Controls"
    case settings = "Settings"
    case license = "License"
    case about = "About"
    case states = "States"

    var icon: String {
        switch self {
        case .foundations: "square.stack.3d.up"
        case .controls: "switch.2"
        case .settings: "gearshape"
        case .license: "key.fill"
        case .about: "info.circle"
        case .states: "exclamationmark.bubble"
        }
    }

    var iconColor: Color {
        switch self {
        case .foundations: .cyan
        case .controls: SanePanelChrome.accentTeal
        case .settings: .orange
        case .license: .yellow
        case .about: .blue
        case .states: .green
        }
    }
}

@main
struct SaneUICatalogApp: App {
    @State private var selectedTab: CatalogTab? = .settings

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup("SaneUI Catalog") {
            SaneSettingsContainer(defaultTab: .settings, selection: $selectedTab) { tab in
                switch tab {
                case .foundations:
                    CatalogScrollView {
                        FoundationsCatalogView()
                    }
                case .controls:
                    CatalogScrollView {
                        ControlsCatalogView()
                    }
                case .settings:
                    CatalogScrollView {
                        SettingsCatalogView()
                    }
                case .license:
                    CatalogScrollView {
                        LicenseCatalogView()
                    }
                case .about:
                    AboutCatalogView()
                case .states:
                    CatalogScrollView {
                        StatesCatalogView()
                    }
                }
            }
            .preferredColorScheme(.dark)
            .frame(minWidth: 700, idealWidth: 720, minHeight: 420, idealHeight: 460)
        }
    }
}

private struct CatalogScrollView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FoundationsCatalogView: View {
    var body: some View {
        CompactSection("Palette", icon: "paintpalette", iconColor: .cyan) {
            CompactRow("Accent") {
                swatch(.saneAccent)
            }
            CompactDivider()
            CompactRow("Accent Teal") {
                swatch(SanePanelChrome.accentTeal)
            }
            CompactDivider()
            CompactRow("Control Navy") {
                swatch(SanePanelChrome.controlNavyDeep)
            }
            CompactDivider()
            CompactRow("Panel Tint") {
                swatch(SanePanelChrome.panelTint)
            }
        }

        CompactSection("Background", icon: "sparkles.rectangle.stack", iconColor: .blue) {
            Text("Use the calmer panel gradient for shared settings, detail views, and overlay-backed controls.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
    }

    private func swatch(_ color: Color) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(width: 54, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

private struct ControlsCatalogView: View {
    @State private var selectedChoice = "Weekly"
    @State private var lastButtonAction: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CompactSection("Buttons", icon: "capsule.portrait", iconColor: .teal) {
                CompactRow("Primary") {
                    ActionButton("Save", icon: "checkmark", style: .primary) {
                        lastButtonAction = "Primary action preview fired"
                    }
                }
                CompactDivider()
                CompactRow("Secondary") {
                    ActionButton("Cancel", icon: "xmark", style: .secondary) {
                        lastButtonAction = "Secondary action preview fired"
                    }
                }
                CompactDivider()
                CompactRow("Destructive") {
                    ActionButton("Delete", icon: "trash", style: .destructive) {
                        lastButtonAction = "Destructive action preview fired"
                    }
                }
            }

            if let lastButtonAction {
                Text(lastButtonAction)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
            }

            CompactSection("Badges", icon: "tag", iconColor: .orange) {
                CompactRow("Status") {
                    HStack(spacing: 8) {
                        StatusBadge("Active", color: .green, icon: "checkmark.circle.fill")
                        StatusBadge("Warning", color: .orange, icon: "exclamationmark.triangle.fill")
                    }
                }
                CompactDivider()
                CompactRow("Accent") {
                    HStack(spacing: 8) {
                        SaneAccentBadge(title: "Pro", systemImage: "sparkles")
                        SaneAccentBadge(title: "On-Device")
                    }
                }
            }

            CompactSection("Segmented Choice", icon: "rectangle.split.3x1", iconColor: .purple) {
                HStack(spacing: 8) {
                    ForEach(["Daily", "Weekly"], id: \.self) { title in
                        SaneSegmentedChoiceButton(
                            title: title,
                            isSelected: selectedChoice == title
                        ) {
                            selectedChoice = title
                        }
                    }
                }
                .padding(12)
            }
        }
    }
}

private struct SettingsCatalogView: View {
    @State private var showDockIcon = false
    @State private var automaticallyChecks = true
    @State private var checkFrequency: SaneSparkleCheckFrequency = .daily

    var body: some View {
        CompactSection("Startup", icon: "power", iconColor: .orange) {
            SaneLoginItemToggle()
                .disabled(true)
            CompactDivider()
            SaneDockIconToggle(showDockIcon: $showDockIcon)
                .disabled(true)
            CompactDivider()
            Text("Preview only. Startup toggles stay off so the host Mac never changes.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }

        CompactSection("Software Updates", icon: "arrow.triangle.2.circlepath", iconColor: .saneAccent) {
            SaneSparkleRow(
                automaticallyChecks: $automaticallyChecks,
                checkFrequency: $checkFrequency,
                onCheckNow: {}
            )
        }
    }
}

private struct LicenseCatalogView: View {
    private enum LicensePreview: String, CaseIterable {
        case basic = "Basic"
        case pro = "Pro"
        case setapp = "Setapp"
    }

    @State private var basicService = LicenseService(
        appName: "SaneUI Catalog",
        checkoutURL: LicenseService.directCheckoutURL(appSlug: "saneui")
    )
    @State private var proService = LicenseService(
        appName: "SaneUI Catalog",
        checkoutURL: LicenseService.directCheckoutURL(appSlug: "saneui")
    )
    @State private var setappService = LicenseService(
        appName: "SaneUI Catalog",
        purchaseBackend: .setapp
    )
    @State private var selectedPreview: LicensePreview = .basic

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shared license states")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text("Shared Basic, Pro, and Setapp layouts every app should inherit.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach(LicensePreview.allCases, id: \.self) { preview in
                    SaneSegmentedChoiceButton(
                        title: preview.rawValue,
                        isSelected: selectedPreview == preview
                    ) {
                        selectedPreview = preview
                    }
                }
            }
            .padding(12)

            Group {
                switch selectedPreview {
                case .basic:
                    LicenseSettingsView(licenseService: basicService, style: .panel)
                case .pro:
                    LicenseSettingsView(licenseService: proService, style: .panel)
                case .setapp:
                    LicenseSettingsView(licenseService: setappService, style: .panel)
                }
            }
            .frame(maxWidth: 520)
        }
        .task {
            syncLicensePreview(.basic)
            syncLicensePreview(.pro)
            syncLicensePreview(.setapp)
        }
        .onChange(of: selectedPreview) { _, preview in
            syncLicensePreview(preview)
        }
        .onChange(of: proService.isLicensed) { _, isLicensed in
            if selectedPreview == .pro, !isLicensed {
                selectedPreview = .basic
            }
        }
    }

    @MainActor
    private func syncLicensePreview(_ preview: LicensePreview) {
        switch preview {
        case .basic:
            basicService.applyDemoState(isLicensed: false)
        case .pro:
            proService.applyDemoState(
                isLicensed: true,
                licenseEmail: "pro@saneapps.com"
            )
        case .setapp:
            setappService.applyDemoState(isLicensed: true)
        }
    }
}

private struct AboutCatalogView: View {
    private let diagnosticsService = SaneDiagnosticsService(
        appName: "SaneUI Catalog",
        subsystem: "com.saneapps.saneui.catalog",
        githubRepo: "SaneUI",
        settingsCollector: {
            "Catalog preview\n- Tab: About\n- Purpose: visual source-of-truth inspection"
        }
    )

    var body: some View {
        SaneAboutView(
            appName: "SaneUI Catalog",
            githubRepo: "SaneUI",
            diagnosticsService: diagnosticsService,
            licenses: [
                .init(
                    name: "SaneUI",
                    url: "https://github.com/sane-apps/SaneUI",
                    text: "PolyForm Shield 1.0.0 — free for personal use and experimentation. Not for competing products."
                )
            ],
            feedbackExtraAttachments: [
                ("slider.horizontal.3", "Catalog state and selected tab")
            ],
            versionLineText: "Shared Source of Truth",
            identitySymbolName: "square.stack.3d.up.fill",
            identitySymbolColor: .cyan
        )
    }
}

private struct StatesCatalogView: View {
    private enum PreviewState: String, CaseIterable {
        case empty = "Empty"
        case error = "Error"
        case loading = "Loading"
    }

    @State private var lastStateAction: String?
    @State private var selectedState: PreviewState = .empty

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ForEach(PreviewState.allCases, id: \.self) { state in
                    SaneSegmentedChoiceButton(
                        title: state.rawValue,
                        isSelected: selectedState == state
                    ) {
                        selectedState = state
                    }
                }
            }
            .padding(12)

            currentStateCard

            if let lastStateAction {
                Text(lastStateAction)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private var currentStateCard: some View {
        switch selectedState {
        case .empty:
            stateCard(title: "Empty") {
                SaneEmptyState(
                    icon: "tray",
                    title: "No Items Yet",
                    description: "Add your first item to get started.",
                    actionTitle: "Add Item"
                ) {
                    lastStateAction = "Empty-state action preview fired"
                }
            }
        case .error:
            stateCard(title: "Error") {
                SaneErrorState(
                    message: "Could not load the latest content.",
                    retryTitle: "Try Again"
                ) {
                    lastStateAction = "Error-state retry preview fired"
                }
            }
        case .loading:
            stateCard(title: "Loading") {
                ZStack {
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 16)
                        Spacer()
                    }
                    .padding(18)
                    LoadingOverlay(message: "Loading preview content...")
                }
            }
        }
    }

    private func stateCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                content()
                    .padding(20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .frame(maxWidth: .infinity)
            .frame(height: 190)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
