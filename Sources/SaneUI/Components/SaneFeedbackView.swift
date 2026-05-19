import SwiftUI
#if os(macOS)
    import UniformTypeIdentifiers
#endif

enum SaneFeedbackCopy {
    static let title = "Report an Issue"
    static let subtitle = "Describe the problem. Diagnostics are copied for GitHub, and selected media is prepared in a local folder."
    static let privacyLine = "Nothing is sent automatically. GitHub issues are public, so use email for sensitive logs or media."
    static let mediaInstruction = "After GitHub opens, drag prepared files into the issue. For large videos, paste a file-sharing link."
}

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
    @State private var selectedAttachmentURLs: [URL] = []
    @State private var preparedAttachmentFolder: URL?

    private enum CollectingAction {
        case report
        case copy
    }

    @State private var collectingAction: CollectingAction?
    @State private var didCopyDiagnostics = false
    @State private var reportErrorMessage: String?

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

            VStack(spacing: 12) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        CompactSection("What happened?", icon: "ladybug.fill", iconColor: .orange) {
                            TextEditor(text: $issueDescription)
                                .font(.body)
                                .frame(minHeight: 128)
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

                        #if os(macOS)
                            CompactSection("Photos and Videos", icon: "photo.on.rectangle.angled", iconColor: .blue) {
                                CompactRow("Selected files", icon: "paperclip", iconColor: .blue) {
                                    Button("Add...") { chooseAttachments() }
                                        .buttonStyle(SaneActionButtonStyle())
                                        .controlSize(.small)
                                }

                                if selectedAttachmentURLs.isEmpty {
                                    CompactDivider()
                                    CompactRow("None selected", icon: "photo.badge.plus", iconColor: .blue) { EmptyView() }
                                } else {
                                    ForEach(selectedAttachmentURLs, id: \.self) { url in
                                        CompactDivider()
                                        CompactRow(url.lastPathComponent, icon: "doc", iconColor: .blue) {
                                            Button("Remove") { removeAttachment(url) }
                                                .buttonStyle(SaneActionButtonStyle())
                                                .controlSize(.small)
                                        }
                                    }
                                }

                                if let preparedAttachmentFolder {
                                    CompactDivider()
                                    CompactRow("Attachment package ready", icon: "folder", iconColor: .green) {
                                        Button("Show") {
                                            NSWorkspace.shared.activateFileViewerSelecting([preparedAttachmentFolder])
                                        }
                                        .buttonStyle(SaneActionButtonStyle())
                                        .controlSize(.small)
                                    }
                                    CompactDivider()
                                    CompactRow(SaneFeedbackCopy.mediaInstruction, icon: "arrow.up.doc", iconColor: .orange) {
                                        EmptyView()
                                    }
                                }
                            }
                        #endif

                        if let reportErrorMessage {
                            CompactSection("Needs Attention", icon: "exclamationmark.triangle.fill", iconColor: .orange) {
                                CompactRow(reportErrorMessage, icon: "exclamationmark.triangle", iconColor: .orange) {
                                    EmptyView()
                                }
                            }
                        }

                        CompactSection("Privacy", icon: "lock.shield", iconColor: .green) {
                            CompactRow(
                                SaneFeedbackCopy.privacyLine,
                                icon: "checkmark.shield",
                                iconColor: .green
                            ) { EmptyView() }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                }

                footer
            }
            .padding(.vertical, 16)
        }
        #if os(macOS)
        .frame(width: 540, height: 660)
        #endif
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(SaneFeedbackCopy.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(SaneFeedbackCopy.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
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
            Spacer(minLength: 0)

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(SaneActionButtonStyle())
            .keyboardShortcut(.cancelAction)

            Button {
                copyDiagnostics()
            } label: {
                if collectingAction == .copy {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Text(didCopyDiagnostics ? "Copied" : "Copy")
                }
            }
            .buttonStyle(SaneActionButtonStyle())
            .disabled(collectingAction != nil)

            Button {
                submitReport()
            } label: {
                if collectingAction == .report {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Text("Report")
                }
            }
            .buttonStyle(SaneActionButtonStyle(prominent: true))
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
        reportErrorMessage = nil

        if !selectedAttachmentURLs.isEmpty {
            do {
                let folder = try Self.prepareAttachmentPackage(
                    report: report,
                    userDescription: issueDescription,
                    attachmentURLs: selectedAttachmentURLs
                )
                preparedAttachmentFolder = folder
                #if os(macOS)
                    NSWorkspace.shared.activateFileViewerSelecting([folder])
                #endif
            } catch {
                reportErrorMessage = "I couldn't prepare the selected files. Try removing large or unavailable files, or use a file-sharing link."
                return
            }
        }

        if let preparedAttachmentFolder {
            #if os(macOS)
                NSWorkspace.shared.activateFileViewerSelecting([preparedAttachmentFolder])
            #endif
        }

        let firstLine = issueDescription.components(separatedBy: .newlines).first ?? ""
        let title = String(firstLine.prefix(60))
        if let url = report.gitHubIssueURL(
            title: title,
            userDescription: issueDescription,
            githubRepo: diagnosticsService.githubRepo
        ) {
            SanePlatform.open(url)
            if selectedAttachmentURLs.isEmpty {
                dismiss()
            }
        }
    }

    #if os(macOS)
        private func chooseAttachments() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.image, .movie, .video, .quickTimeMovie, .mpeg4Movie]
            if panel.runModal() == .OK {
                let existing = Set(selectedAttachmentURLs)
                selectedAttachmentURLs.append(contentsOf: panel.urls.filter { !existing.contains($0) })
            }
        }

        private func removeAttachment(_ url: URL) {
            selectedAttachmentURLs.removeAll { $0 == url }
        }
    #endif

    static func attachmentPackageDirectoryName(appName: String, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return "\(appName)-Issue-\(formatter.string(from: date))"
    }

    static func prepareAttachmentPackage(
        report: SaneDiagnosticReport,
        userDescription: String,
        attachmentURLs: [URL],
        baseDirectory: URL = FileManager.default.temporaryDirectory
    ) throws -> URL {
        let directory = baseDirectory
            .appendingPathComponent("SaneApps-Issue-Attachments", isDirectory: true)
            .appendingPathComponent(attachmentPackageDirectoryName(appName: report.appName), isDirectory: true)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let diagnosticsURL = directory.appendingPathComponent("diagnostics.md")
        try report.toMarkdown(userDescription: userDescription).write(to: diagnosticsURL, atomically: true, encoding: .utf8)

        for sourceURL in attachmentURLs {
            let destinationURL = uniqueDestinationURL(for: sourceURL.lastPathComponent, in: directory)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }

        return directory
    }

    private static func uniqueDestinationURL(for filename: String, in directory: URL) -> URL {
        let base = URL(fileURLWithPath: filename).deletingPathExtension().lastPathComponent
        let ext = URL(fileURLWithPath: filename).pathExtension

        var candidate = directory.appendingPathComponent(filename)
        var index = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let indexedName = ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"
            candidate = directory.appendingPathComponent(indexedName)
            index += 1
        }
        return candidate
    }
}
