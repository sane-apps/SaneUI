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
    @Environment(\.colorScheme) private var colorScheme

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
        iconColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.leading, 4)

            // Content with glass background
            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.12) : Color.teal.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: colorScheme == .dark ? .black.opacity(0.15) : .teal.opacity(0.08),
                radius: colorScheme == .dark ? 8 : 6,
                x: 0,
                y: 3
            )
        }
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
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()
                .padding(.leading, 12)

            HStack {
                Text("Item 2")
                Spacer()
                Text("Value")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
    .padding(20)
    .frame(width: 400)
    .background(SaneGradientBackground())
}
