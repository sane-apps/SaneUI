import SwiftUI

// MARK: - Compact Row

/// A standard row with icon, label, and trailing content.
///
/// Use inside a `CompactSection` for consistent layout.
///
/// ```swift
/// CompactRow("Storage", icon: "externaldrive", iconColor: .orange) {
///     Text("256 GB")
///         .font(SaneTypography.body)
///         .foregroundStyle(SaneTypography.text)
/// }
/// ```
public struct CompactRow<Content: View>: View {
    let label: String
    let icon: String?
    let iconColor: Color
    let content: Content

    public init(
        _ label: String,
        icon: String? = nil,
        iconColor: Color = .white,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: SaneTypography.bodySize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
            }
            Text(label)
                .font(SaneTypography.label)
                .foregroundStyle(SaneTypography.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            content
                .environment(\.font, SaneTypography.body)
                .foregroundStyle(SaneTypography.text)
                .controlSize(.regular)
        }
        .environment(\.font, SaneTypography.label)
        .environment(\.controlSize, .regular)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Compact Toggle

/// A toggle switch row with icon and label.
///
/// Uses a tappable `HStack` (not `Button`) so macOS control sizing cannot shrink
/// the absolute 16pt label font.
public struct CompactToggle: View {
    let label: String
    let icon: String?
    let iconColor: Color
    @Binding var isOn: Bool

    public init(
        label: String,
        icon: String? = nil,
        iconColor: Color = .white,
        isOn: Binding<Bool>
    ) {
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
        _isOn = isOn
    }

    public var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: SaneTypography.bodySize, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 24)
            }
            Text(label)
                .font(SaneTypography.label)
                .foregroundStyle(SaneTypography.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            switchIndicator
        }
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
        .environment(\.font, SaneTypography.body)
        .environment(\.controlSize, .regular)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityAction { isOn.toggle() }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var switchIndicator: some View {
        Capsule()
            .fill(isOn ? SanePanelChrome.accentStart : Color.white.opacity(0.28))
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: 20)
                    .padding(3)
            }
            .frame(width: 48, height: 26)
            .accessibilityHidden(true)
    }
}

// MARK: - Compact Divider

public struct CompactDivider: View {
    public init() {}

    public var body: some View {
        Divider()
            .overlay(Color.white.opacity(0.18))
            .padding(.leading, 14)
    }
}

#Preview("Rows and Toggles") {
    VStack(spacing: 20) {
        CompactSection("Rows", icon: "list.bullet", iconColor: .blue) {
            CompactRow("Simple Row", icon: "star", iconColor: .yellow) {
                Text("Value")
            }
            CompactDivider()
            CompactRow("Another Row", icon: "heart", iconColor: .red) {
                Image(systemName: "chevron.right")
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
