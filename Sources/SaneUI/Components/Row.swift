import SwiftUI

// MARK: - Compact Row

/// A standard row with icon, label, and trailing content.
///
/// Use inside a `CompactSection` for consistent layout.
///
/// ```swift
/// CompactRow("Storage", icon: "externaldrive", iconColor: .orange) {
///     Text("256 GB")
///         .foregroundStyle(.secondary)
/// }
/// ```
public struct CompactRow<Content: View>: View {
    let label: String
    let icon: String?
    let iconColor: Color
    let content: Content

    /// Creates a new compact row
    /// - Parameters:
    ///   - label: The row label
    ///   - icon: Optional SF Symbol name
    ///   - iconColor: Color for the icon
    ///   - content: Trailing content
    public init(
        _ label: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    public var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 20)
            }
            Text(label)
            Spacer()
            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Compact Toggle

/// A toggle switch row with icon and label.
///
/// Use inside a `CompactSection` for settings toggles.
///
/// ```swift
/// CompactToggle(
///     label: "Dark Mode",
///     icon: "moon.fill",
///     iconColor: .purple,
///     isOn: $isDarkMode
/// )
/// ```
public struct CompactToggle: View {
    let label: String
    let icon: String?
    let iconColor: Color
    @Binding var isOn: Bool

    /// Creates a new compact toggle
    /// - Parameters:
    ///   - label: The toggle label
    ///   - icon: Optional SF Symbol name
    ///   - iconColor: Color for the icon
    ///   - isOn: Binding to the toggle state
    public init(
        label: String,
        icon: String? = nil,
        iconColor: Color = .secondary,
        isOn: Binding<Bool>
    ) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self._isOn = isOn
    }

    public var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 20)
            }
            Text(label)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Compact Divider

/// An inset divider for separating rows within a section.
///
/// ```swift
/// CompactRow("Item 1") { Text("Value") }
/// CompactDivider()
/// CompactRow("Item 2") { Text("Value") }
/// ```
public struct CompactDivider: View {
    /// Creates a new compact divider
    public init() {}

    public var body: some View {
        Divider()
            .padding(.leading, 12)
    }
}

// MARK: - Preview

#Preview("Rows and Toggles") {
    VStack(spacing: 20) {
        CompactSection("Rows", icon: "list.bullet", iconColor: .blue) {
            CompactRow("Simple Row", icon: "star", iconColor: .yellow) {
                Text("Value")
                    .foregroundStyle(.secondary)
            }
            CompactDivider()
            CompactRow("Another Row", icon: "heart", iconColor: .red) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }

        CompactSection("Toggles", icon: "switch.2", iconColor: .green) {
            CompactToggle(label: "Option One", icon: "1.circle", iconColor: .blue, isOn: .constant(true))
            CompactDivider()
            CompactToggle(label: "Option Two", icon: "2.circle", iconColor: .purple, isOn: .constant(false))
        }
    }
    .padding(20)
    .frame(width: 400)
    .background(SaneGradientBackground())
}
