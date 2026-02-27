import AppKit
import SwiftUI

/// Standardized About section for all SaneApps settings views.
///
/// Provides: app icon, version, trust messaging, and a consistent set of links
/// (GitHub, Licenses, Donate, Report a Bug, View Issues, Email).
///
/// ```swift
/// SaneAboutView(
///     appName: "SaneBar",
///     githubRepo: "SaneBar",
///     diagnosticsService: myDiagnosticsService,
///     licenses: [
///         .init(name: "KeyboardShortcuts", url: "https://github.com/sindresorhus/KeyboardShortcuts", text: "MIT License..."),
///         .init(name: "Sparkle", url: "https://sparkle-project.org", text: "MIT License...")
///     ]
/// )
/// ```
public struct SaneAboutView: View {
    private let appName: String
    private let githubRepo: String
    private let diagnosticsService: SaneDiagnosticsService?
    private let licenses: [LicenseEntry]
    private let feedbackExtraAttachments: [(icon: String, label: String)]

    @State private var showLicenses = false
    @State private var showSupport = false
    @State private var showFeedback = false

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
        feedbackExtraAttachments: [(icon: String, label: String)] = []
    ) {
        self.appName = appName
        self.githubRepo = githubRepo
        self.diagnosticsService = diagnosticsService
        self.licenses = licenses
        self.feedbackExtraAttachments = feedbackExtraAttachments
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App identity
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)

            VStack(spacing: 8) {
                Text(appName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.92))
                }
            }

            // Trust messaging
            HStack(spacing: 0) {
                Text("Made with \u{2764}\u{FE0F} in \u{1F1FA}\u{1F1F8}")
                    .fontWeight(.medium)
                Text(" \u{00B7} ")
                Text("100% On-Device")
                Text(" \u{00B7} ")
                Text("No Analytics")
            }
            .font(.callout)
            .foregroundStyle(.white.opacity(0.92))
            .padding(.top, 4)

            // Links — two rows
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Link(destination: URL(string: "https://github.com/sane-apps/\(githubRepo)")!) {
                        Label("GitHub", systemImage: "link")
                    }

                    if !licenses.isEmpty {
                        Button {
                            showLicenses = true
                        } label: {
                            Label("Licenses", systemImage: "doc.text")
                        }
                    }

                    Button {
                        showSupport = true
                    } label: {
                        Label {
                            Text("Donate")
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        if diagnosticsService != nil {
                            showFeedback = true
                        } else {
                            // No diagnostics — link directly to GitHub Issues
                            if let url = URL(string: "https://github.com/sane-apps/\(githubRepo)/issues") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    } label: {
                        Label("Report a Bug", systemImage: "ladybug")
                    }

                    Link(destination: URL(string: "https://github.com/sane-apps/\(githubRepo)/issues")!) {
                        Label("View Issues", systemImage: "arrow.up.right.square")
                    }

                    Link(destination: URL(string: "mailto:hi@saneapps.com")!) {
                        Label("Email Me", systemImage: "envelope")
                    }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .padding(.top, 12)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .popover(isPresented: $showLicenses, arrowEdge: .bottom) {
            licensesPopover
        }
        .popover(isPresented: $showSupport, arrowEdge: .bottom) {
            supportPopover
        }
        .popover(isPresented: $showFeedback, arrowEdge: .bottom) {
            if let diagnosticsService {
                SaneFeedbackView(
                    diagnosticsService: diagnosticsService,
                    extraAttachments: feedbackExtraAttachments
                )
            }
        }
    }

    // MARK: - Licenses Popover

    private var licensesPopover: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Third-Party Licenses")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    showLicenses = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(licenses) { license in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 8) {
                                Link(license.name, destination: URL(string: license.url)!)
                                    .font(.headline)

                                Text(license.text)
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 500, height: 400)
    }

    // MARK: - Support / Donate Popover

    private var supportPopover: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Donate to \(appName)")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    showSupport = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Quote
                    VStack(spacing: 4) {
                        Text("\"The worker is worthy of his wages.\"")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .italic()
                        Text("— 1 Timothy 5:18")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(.top, 8)

                    // Personal message
                    Text("I need your help to keep \(appName) alive. Your support — whether one-time or monthly — makes this possible. Thank you.")
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Text("— Mr. Sane")
                        .font(.system(size: 13, weight: .medium))
                        .multilineTextAlignment(.center)

                    Divider()
                        .padding(.horizontal, 40)

                    // GitHub Sponsors
                    Link(destination: URL(string: "https://github.com/sponsors/MrSaneApps")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                            Text("Sponsor on GitHub")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.pink.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    // Crypto addresses
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or send crypto:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                        CryptoAddressRow(label: "BTC", address: "3Go9nJu3dj2qaa4EAYXrTsTf5AnhcrPQke")
                        CryptoAddressRow(label: "SOL", address: "FBvU83GUmwEYk3HMwZh3GBorGvrVVWSPb8VLCKeLiWZZ")
                        CryptoAddressRow(label: "ZEC", address: "t1PaQ7LSoRDVvXLaQTWmy5tKUAiKxuE9hBN")
                    }
                    .padding()
                    .background(.fill.quaternary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
            }
        }
        .frame(width: 420, height: 360)
    }
}

// MARK: - Crypto Address Row

private struct CryptoAddressRow: View {
    let label: String
    let address: String
    @State private var copied = false

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.blue)
                .frame(width: 36, alignment: .leading)

            Text(address)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(address, forType: .string)
                copied = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    copied = false
                }
            } label: {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderless)
            .foregroundStyle(copied ? .green : .white.opacity(0.9))
        }
    }
}
