#if os(macOS)
    import AppKit
    import SwiftUI

    public enum SaneSystemSettingsDestination: String, CaseIterable, Sendable {
        case accessibility
        case automation
        case screenRecording
        case microphone
        case camera
        case photos
        case filesAndFolders
        case fullDiskAccess
        case loginItems

        public var url: URL {
            switch self {
            case .accessibility:
                privacyURL("Accessibility")
            case .automation:
                privacyURL("Automation")
            case .screenRecording:
                privacyURL("ScreenCapture")
            case .microphone:
                privacyURL("Microphone")
            case .camera:
                privacyURL("Camera")
            case .photos:
                privacyURL("Photos")
            case .filesAndFolders:
                privacyURL("FilesAndFolders")
            case .fullDiskAccess:
                privacyURL("AllFiles")
            case .loginItems:
                URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
            }
        }

        @inline(never)
        private func privacyURL(_ pane: String) -> URL {
            let prefix = String(decoding: [
                120, 45, 97, 112, 112, 108, 101, 46, 115, 121, 115, 116, 101, 109, 112, 114,
                101, 102, 101, 114, 101, 110, 99, 101, 115, 58, 99, 111, 109, 46, 97, 112,
                112, 108, 101, 46, 112, 114, 101, 102, 101, 114, 101, 110, 99, 101, 46,
                115, 101, 99, 117, 114, 105, 116, 121, 63, 80, 114, 105, 118, 97, 99,
                121, 95
            ], as: UTF8.self)
            return URL(string: prefix + pane)!
        }

        @MainActor
        public func open() {
            NSWorkspace.shared.open(url)
        }
    }

    public struct SanePermissionAction: Identifiable {
        public let id = UUID()
        public let title: String
        public let systemImage: String
        public let url: URL
        public let help: String
        public let prominent: Bool

        public init(
            title: String,
            systemImage: String = "arrow.up.forward.app",
            destination: SaneSystemSettingsDestination,
            help: String? = nil,
            prominent: Bool = false
        ) {
            self.init(
                title: title,
                systemImage: systemImage,
                url: destination.url,
                help: help ?? "Open \(title).",
                prominent: prominent
            )
        }

        public init(
            title: String,
            systemImage: String = "arrow.up.forward.app",
            url: URL,
            help: String? = nil,
            prominent: Bool = false
        ) {
            self.title = title
            self.systemImage = systemImage
            self.url = url
            self.help = help ?? "Open \(title)."
            self.prominent = prominent
        }

        @MainActor
        public func open() {
            NSWorkspace.shared.open(url)
        }
    }

    public struct SanePermissionGuidanceView: View {
        private let title: String
        private let message: String
        private let steps: [String]
        private let icon: String
        private let iconColor: Color
        private let primaryAction: SanePermissionAction?
        private let secondaryAction: SanePermissionAction?

        public init(
            title: String,
            message: String,
            steps: [String] = [],
            icon: String = "hand.raised.fill",
            iconColor: Color = SanePanelChrome.accentTeal,
            primaryAction: SanePermissionAction? = nil,
            secondaryAction: SanePermissionAction? = nil
        ) {
            self.title = title
            self.message = message
            self.steps = steps
            self.icon = icon
            self.iconColor = iconColor
            self.primaryAction = primaryAction
            self.secondaryAction = secondaryAction
        }

        public var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                header

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .saneHelp(message)

                if !steps.isEmpty {
                    stepsView
                }

                if primaryAction != nil || secondaryAction != nil {
                    actionRow
                }
            }
            .padding(22)
            .frame(maxWidth: 640, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SanePanelChrome.controlNavyDeep.opacity(0.74))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
        }

        private var header: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
            }
        }

        private var stepsView: some View {
            CompactSection("Steps", icon: "list.number", iconColor: iconColor) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(
                                    Circle()
                                        .fill(iconColor.opacity(0.32))
                                )

                            Text(step)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                                .saneHelp(step)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }

        private var actionRow: some View {
            HStack(spacing: 10) {
                if let primaryAction {
                    actionButton(primaryAction)
                }

                if let secondaryAction {
                    actionButton(secondaryAction)
                }

                Spacer(minLength: 0)
            }
        }

        private func actionButton(_ action: SanePermissionAction) -> some View {
            Button {
                action.open()
            } label: {
                Label(action.title, systemImage: action.systemImage)
            }
            .buttonStyle(SaneActionButtonStyle(prominent: action.prominent))
            .controlSize(.small)
            .help(action.help)
        }
    }
#endif
