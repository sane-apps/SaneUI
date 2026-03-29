#if os(macOS)
import AppKit
import SwiftUI

/// Standardized About section for SaneApps settings views.
///
/// Provides: app identity, trust messaging, and a compact action grid
/// for the most common destinations.
///
/// ```swift
/// SaneAboutView(
///     appName: "SaneBar",
///     githubRepo: "SaneBar",
///     diagnosticsService: myDiagnosticsService,
///     licenses: [
///         .init(name: "Dependency Name", url: "https://example.com", text: "License summary..."),
///         .init(name: "Another Dependency", url: "https://example.com", text: "License summary...")
///     ]
/// )
/// ```
public struct SaneAboutView: View {
    private let appName: String
    private let githubRepo: String
    private let diagnosticsService: SaneDiagnosticsService?
    private let licenses: [LicenseEntry]
    private let feedbackExtraAttachments: [(icon: String, label: String)]
    private let versionLineText: String?
    private let identitySymbolName: String?
    private let identitySymbolColor: Color

    @State private var activeSheet: SheetDestination?

    private enum SheetDestination: String, Identifiable {
        case licenses
        case feedback

        var id: String { rawValue }
    }

    /// A third-party license entry shown in the Licenses popover.
    public struct LicenseEntry: Identifiable {
        public let id = UUID()
        public let name: String
        public let url: String
        public let text: String

        public init(name: String, url: String, text: String) {
            self.name = name
            self.url = url
            self.text = text
        }
    }

    /// Create a standardized About view.
    /// - Parameters:
    ///   - appName: Display name (e.g. "SaneBar")
    ///   - githubRepo: GitHub repo name under sane-apps org (e.g. "SaneBar")
    ///   - diagnosticsService: If provided, enables the "Report a Bug" button with full diagnostics.
    ///     If nil, "Report a Bug" links directly to GitHub Issues.
    ///   - licenses: Third-party licenses to display in the Licenses popover.
    ///   - feedbackExtraAttachments: Extra items for the feedback form's "We'll automatically attach" list.
    public init(
        appName: String,
        githubRepo: String,
        diagnosticsService: SaneDiagnosticsService? = nil,
        licenses: [LicenseEntry] = [],
        feedbackExtraAttachments: [(icon: String, label: String)] = [],
        versionLineText: String? = nil,
        identitySymbolName: String? = nil,
        identitySymbolColor: Color = .saneAccent
    ) {
        self.appName = appName
        self.githubRepo = githubRepo
        self.diagnosticsService = diagnosticsService
        self.licenses = licenses
        self.feedbackExtraAttachments = feedbackExtraAttachments
        self.versionLineText = versionLineText
        self.identitySymbolName = identitySymbolName
        self.identitySymbolColor = identitySymbolColor
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                identityView
                    .padding(.top, 4)

                VStack(spacing: 6) {
                    Text(appName)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text(SaneAboutViewPolicy.versionLine(bundle: .main, override: versionLineText))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    (
                        Text("\(SaneAboutViewPolicy.primaryTrustPrefix) ")
                            .fontWeight(.medium) +
                        Text(Image(systemName: "heart.fill"))
                            .foregroundStyle(.pink)
                            .fontWeight(.medium) +
                        Text(" \(SaneAboutViewPolicy.primaryTrustSuffix)")
                            .fontWeight(.medium)
                    )
                    Text(SaneAboutViewPolicy.secondaryTrustLine)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

                LazyVGrid(
                    columns: [
                        GridItem(.flexible(minimum: 150), spacing: 10),
                        GridItem(.flexible(minimum: 150), spacing: 10)
                    ],
                    spacing: 10
                ) {
                    aboutActionButton(title: "GitHub", icon: "link") {
                        openURL(SaneAboutViewPolicy.repositoryURL(githubRepo: githubRepo))
                    }

                    if !licenses.isEmpty {
                        aboutActionButton(title: "Licenses", icon: "doc.text") {
                            activeSheet = .licenses
                        }
                    }

                    aboutActionButton(title: "Report a Bug", icon: "ladybug") {
                        openBugReporter()
                    }

                    aboutActionButton(title: "View Issues", icon: "arrow.up.right.square") {
                        openURL(SaneAboutViewPolicy.issuesURL(githubRepo: githubRepo))
                    }
                }
                .frame(maxWidth: 420)
                .padding(.top, 2)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .sheet(item: $activeSheet) { destination in
            switch destination {
            case .licenses:
                licensesPopover
            case .feedback:
                if let diagnosticsService {
                    SaneFeedbackView(
                        diagnosticsService: diagnosticsService,
                        extraAttachments: feedbackExtraAttachments
                    )
                } else {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var identityView: some View {
        if let identitySymbolName {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                identitySymbolColor.opacity(0.82),
                                identitySymbolColor.opacity(0.34)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)

                Image(systemName: identitySymbolName)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
        } else {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        }
    }

    private func aboutActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(SaneActionButtonStyle())
    }

    private func openBugReporter() {
        if diagnosticsService != nil {
            activeSheet = .feedback
            return
        }

        openURL(SaneAboutViewPolicy.issuesURL(githubRepo: githubRepo))
    }

    private func openURL(_ url: URL?) {
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Licenses Popover

    private var licensesPopover: some View {
        ZStack {
            SaneGradientBackground(style: .panel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Third-Party Licenses")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Done") {
                        activeSheet = nil
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                    .keyboardShortcut(.defaultAction)
                }
                .padding()

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(licenses) { license in
                            CompactSection(license.name, icon: "doc.text", iconColor: .cyan) {
                                CompactRow("Source") {
                                    Button("Open Source") {
                                        openURL(URL(string: license.url))
                                    }
                                    .buttonStyle(SaneActionButtonStyle())
                                    .controlSize(.small)
                                }
                                CompactDivider()
                                Text(license.text)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 540, height: 460)
    }
}

enum SaneAboutViewPolicy {
    static let primaryTrustPrefix = "Made with"
    static let primaryTrustSuffix = "in the USA"
    static let secondaryTrustLine = "On-Device by Default · No Personal Data"

    static func repositoryURL(githubRepo: String) -> URL? {
        URL(string: "https://github.com/sane-apps/\(githubRepo)")
    }

    static func issuesURL(githubRepo: String) -> URL? {
        URL(string: "https://github.com/sane-apps/\(githubRepo)/issues")
    }

    static func showsSupportSection(channel: SaneDistributionChannel) -> Bool {
        channel.showsSupportSection
    }

    static func showsSupportSection(usesAppStoreBuild: Bool) -> Bool {
        showsSupportSection(channel: usesAppStoreBuild ? .appStore : .direct)
    }

    static func versionLine(bundle: Bundle = .main, override: String? = nil) -> String {
        if let override, !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return override
        }

        if let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
           !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Version \(version)"
        }

        return "Shared Source of Truth"
    }
}
#endif
