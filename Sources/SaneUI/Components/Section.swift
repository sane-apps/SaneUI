import SwiftUI

// MARK: - Compact Section

/// A grouped section with header, glass background, and shadow.
///
/// Use this to group related content in settings or detail views.
///
/// ```swift
/// CompactSection("General", icon: "gear", iconColor: .gray) {
///     CompactToggle(label: "Enable", isOn: $enabled)
///     CompactDivider()
///     CompactRow("Version") {
///         Text("1.0")
///     }
/// }
/// ```
public struct CompactSection<Content: View>: View {
    let title: String
    let icon: String?
    let iconColor: Color
    let content: Content

    /// Creates a new compact section
    /// - Parameters:
    ///   - title: The section header title
    ///   - icon: Optional SF Symbol name for the header icon
    ///   - iconColor: Color for the header icon
    ///   - content: The section content
    public init(
        _ title: String,
        icon: String? = nil,
        iconColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(SaneTypography.section)
                    .foregroundStyle(SaneTypography.text)
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content
            }
            .environment(\.font, SaneTypography.body)
            .environment(\.controlSize, .regular)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                SaneGlassRoundedBackground(
                    cornerRadius: 14,
                    tint: SanePanelChrome.panelTint,
                    tintStrength: 0.12,
                    glowOpacity: 0.14,
                    interactive: true,
                    shadowOpacity: 0.28,
                    shadowRadius: 16,
                    shadowY: 6
                )
            )
            .padding(.horizontal, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview("CompactSection") {
    VStack(spacing: 20) {
        CompactSection("Settings", icon: "gear", iconColor: .gray) {
            Text("Content here")
                .padding()
        }

        CompactSection("With Multiple Items", icon: "list.bullet", iconColor: .blue) {
            HStack {
                Text("Item 1")
                Spacer()
                Text("Value")
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 12)

            HStack {
                Text("Item 2")
                Spacer()
                Text("Value")
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
    .padding(20)
    .frame(width: 400)
    .background(SaneGradientBackground())
}
