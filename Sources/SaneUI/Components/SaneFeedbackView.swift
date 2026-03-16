import SwiftUI

/// In-app issue reporting view with diagnostic log collection.
/// Shared across all SaneApps — each app provides its own `SaneDiagnosticsService`.
///
/// ```swift
/// SaneFeedbackView(diagnosticsService: myDiagnosticsService)
/// ```
public struct SaneFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let diagnosticsService: SaneDiagnosticsService
    /// Optional extra line items describing what gets attached (app-specific).
    /// Default items (version, hardware, logs, settings) are always shown.
    private let extraAttachments: [(icon: String, label: String)]

    @State private var issueDescription = ""

    private enum CollectingAction {
        case report
        case copy
    }

    @State private var collectingAction: CollectingAction?
    @State private var didCopyDiagnostics = false

    /// Create a feedback view backed by the given diagnostics service.
    /// - Parameters:
    ///   - diagnosticsService: The app's configured diagnostics collector.
    ///   - extraAttachments: Additional items to list in "We'll automatically attach"
    ///     (e.g. `("menubar.rectangle", "Menu bar state snapshot")`).
    public init(
        diagnosticsService: SaneDiagnosticsService,
        extraAttachments: [(icon: String, label: String)] = []
    ) {
        self.diagnosticsService = diagnosticsService
        self.extraAttachments = extraAttachments
    }

    public var body: some View {
        ZStack {
            SaneGradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        CompactSection("What happened?", icon: "ladybug.fill", iconColor: .orange) {
                            TextEditor(text: $issueDescription)
                                .font(.body)
                                .frame(minHeight: 160)
                                .padding(10)
                                .background(editorBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.14 : 0.2), lineWidth: 1)
                                )
                                .padding(12)
                                .scrollContentBackground(.hidden)
                        }

                        CompactSection("We'll Attach", icon: "paperclip", iconColor: .teal) {
                            CompactRow("App version and OS", icon: "info.circle", iconColor: .teal) { EmptyView() }
                            CompactDivider()
                            CompactRow("Device and hardware details", icon: "desktopcomputer", iconColor: .blue) { EmptyView() }
                            CompactDivider()
                            CompactRow("Recent logs when available", icon: "doc.text", iconColor: .orange) { EmptyView() }
                            CompactDivider()
                            CompactRow("Current settings summary", icon: "gearshape", iconColor: .green) { EmptyView() }

                            ForEach(extraAttachments.indices, id: \.self) { index in
                                CompactDivider()
                                CompactRow(
                                    extraAttachments[index].label,
                                    icon: extraAttachments[index].icon,
                                    iconColor: .purple
                                ) { EmptyView() }
                            }
                        }

                        CompactSection("Privacy", icon: "lock.shield", iconColor: .green) {
                            CompactRow(
                                "Nothing is sent until GitHub opens in your browser.",
                                icon: "checkmark.shield",
                                iconColor: .green
                            ) { EmptyView() }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }

                footer
            }
            .padding(.vertical, 20)
        }
        #if os(macOS)
            .frame(width: 540, height: 520)
        #endif
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Report an Issue")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("Describe the problem and the diagnostics will be attached automatically.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Link("Questions instead?", destination: URL(string: "mailto:hi@saneapps.com")!)
                .font(.callout)
                .foregroundStyle(.white)

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)

            Button {
                copyDiagnostics()
            } label: {
                if collectingAction == .copy {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Text(didCopyDiagnostics ? "Copied" : "Copy Diagnostics")
                }
            }
            .buttonStyle(.bordered)
            .disabled(collectingAction != nil)

            Button {
                submitReport()
            } label: {
                if collectingAction == .report {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Text("Report Issue")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(issueDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || collectingAction != nil)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 20)
    }

    private var editorBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white.opacity(0.78))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
            )
    }

    private func copyDiagnostics() {
        collectingAction = .copy
        Task {
            let report = await diagnosticsService.collectDiagnostics()
            let description = issueDescription.isEmpty ? "<describe what happened here>" : issueDescription
            let markdown = report.toMarkdown(userDescription: description)

            await MainActor.run {
                SanePlatform.copyToPasteboard(markdown)
                collectingAction = nil
                didCopyDiagnostics = true
            }

            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                didCopyDiagnostics = false
            }
        }
    }

    private func submitReport() {
        collectingAction = .report
        Task {
            let report = await diagnosticsService.collectDiagnostics()
            await MainActor.run {
                collectingAction = nil
                openInGitHub(report: report)
            }
        }
    }

    private func openInGitHub(report: SaneDiagnosticReport) {
        let firstLine = issueDescription.components(separatedBy: .newlines).first ?? ""
        let title = String(firstLine.prefix(60))
        if let url = report.gitHubIssueURL(
            title: title,
            userDescription: issueDescription,
            githubRepo: diagnosticsService.githubRepo
        ) {
            SanePlatform.open(url)
            dismiss()
        }
    }
}
