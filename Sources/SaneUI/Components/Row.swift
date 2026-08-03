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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 22)
            }
            Text(label)
                .font(SaneTypography.body)
                .foregroundStyle(SaneTypography.text)
            Spacer(minLength: 8)
            content
                .font(SaneTypography.body)
                .foregroundStyle(SaneTypography.text)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Compact Toggle

/// A toggle switch row with icon and label.
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
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                        .frame(width: 22)
                }
                Text(label)
                    .font(SaneTypography.body)
                    .foregroundStyle(SaneTypography.text)
                Spacer(minLength: 8)
                switchIndicator
            }
        }
        .controlSize(.regular)
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isOn ? "On" : "Off")
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var switchIndicator: some View {
        Capsule()
            .fill(isOn ? SanePanelChrome.accentStart : Color.white.opacity(0.28))
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .padding(3)
            }
            .frame(width: 44, height: 24)
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
