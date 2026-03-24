import SwiftUI

// MARK: - Status Badge

/// A rounded capsule badge for status indicators.
///
/// ```swift
/// StatusBadge("Active", color: .green, icon: "checkmark.circle.fill")
/// StatusBadge("Warning", color: .orange, icon: "exclamationmark.triangle.fill")
/// ```
public struct StatusBadge: View {
    let text: String
    let color: Color
    let icon: String?

    /// Creates a new status badge
    /// - Parameters:
    ///   - text: The badge text
    ///   - color: The badge color
    ///   - icon: Optional SF Symbol name
    public init(_ text: String, color: Color, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

// MARK: - Action Button

/// A styled action button with icon.
///
/// ```swift
/// ActionButton("Save", icon: "checkmark", style: .primary) {
///     // action
/// }
/// ```
public struct ActionButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    let title: String
    let icon: String?
    let style: Style
    let action: () -> Void

    /// Creates a new action button
    /// - Parameters:
    ///   - title: The button title
    ///   - icon: Optional SF Symbol name
    ///   - style: The button style
    ///   - action: The button action
    public init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(
            SaneActionButtonStyle(
                prominent: style == .primary,
                destructive: style == .destructive
            )
        )
    }

    private var buttonContent: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
            }
            Text(title)
        }
    }
}

public struct SaneActionButtonStyle: ButtonStyle {
    var prominent: Bool
    var destructive: Bool
    var compact: Bool

    public init(
        prominent: Bool = false,
        destructive: Bool = false,
        compact: Bool = false
    ) {
        self.prominent = prominent
        self.destructive = destructive
        self.compact = compact
    }

    public func makeBody(configuration: Configuration) -> some View {
        let tint: Color = if destructive {
            Color(red: 0.86, green: 0.28, blue: 0.30)
        } else if prominent {
            SanePanelChrome.accentTeal
        } else {
            SanePanelChrome.controlNavyDeep
        }

        configuration.label
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white.opacity(configuration.isPressed ? 0.94 : 0.98))
            .padding(.horizontal, compact ? 9 : 12)
            .padding(.vertical, compact ? 4 : 6)
            .background(
                SaneGlassCapsuleBackground(
                    tint: tint,
                    edgeTint: destructive ? Color(red: 0.98, green: 0.60, blue: 0.62) : (prominent ? SanePanelChrome.accentHighlight : SanePanelChrome.accentTeal),
                    tintStrength: destructive
                        ? (configuration.isPressed ? 0.28 : 0.24)
                        : prominent
                            ? (configuration.isPressed ? 0.48 : 0.58)
                            : (configuration.isPressed ? 0.10 : 0.14),
                    glowOpacity: destructive ? 0.10 : (prominent ? 0.22 : 0.08),
                    shadowOpacity: configuration.isPressed ? 0.12 : 0.18,
                    shadowRadius: configuration.isPressed ? 5 : 8,
                    shadowY: configuration.isPressed ? 2 : 3
                )
            )
            .overlay(
                Capsule()
                    .fill(Color.white.opacity(configuration.isPressed ? 0.10 : 0))
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct SaneSegmentedChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    SaneGlassRoundedBackground(
                        cornerRadius: 7,
                        tint: isSelected ? SanePanelChrome.accentTeal : SanePanelChrome.controlNavyDeep,
                        edgeTint: isSelected ? SanePanelChrome.accentHighlight : SanePanelChrome.accentTeal,
                        tintStrength: isSelected ? 0.60 : 0.10,
                        glowOpacity: isSelected ? 0.22 : 0.06,
                        interactive: true,
                        shadowOpacity: isSelected ? 0.18 : 0.12,
                        shadowRadius: isSelected ? 7 : 5,
                        shadowY: 3
                    )
                )
        }
        .buttonStyle(SanePressablePlainStyle())
    }
}

public struct SaneAccentBadge: View {
    let title: String
    var systemImage: String?

    public init(title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 10))
            }
            Text(title)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(SanePanelChrome.accentHighlight)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            SaneGlassCapsuleBackground(
                tint: SanePanelChrome.accentTeal,
                edgeTint: SanePanelChrome.accentHighlight,
                tintStrength: 0.24,
                glowOpacity: 0.10,
                shadowOpacity: 0.10,
                shadowRadius: 5,
                shadowY: 2
            )
        )
    }
}

// MARK: - Color Dot

/// A small colored circle indicator.
///
/// ```swift
/// ColorDot(color: .red)
/// ColorDot(color: .blue, size: 12)
/// ```
public struct ColorDot: View {
    let color: Color
    let size: CGFloat

    /// Creates a new color dot
    /// - Parameters:
    ///   - color: The dot color
    ///   - size: The dot diameter (default: 8)
    public init(color: Color, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Badges and Buttons") {
    VStack(spacing: 20) {
        // Badges
        HStack(spacing: 12) {
            StatusBadge("Active", color: .green, icon: "checkmark.circle.fill")
            StatusBadge("Warning", color: .orange, icon: "exclamationmark.triangle.fill")
            StatusBadge("Error", color: .red, icon: "xmark.circle.fill")
            StatusBadge("Info", color: .blue, icon: "info.circle.fill")
        }

        Divider()

        // Color dots
        HStack(spacing: 8) {
            ColorDot(color: .red)
            ColorDot(color: .orange)
            ColorDot(color: .yellow)
            ColorDot(color: .green)
            ColorDot(color: .blue)
            ColorDot(color: .purple)
        }

        Divider()

        // Buttons
        HStack(spacing: 12) {
            Button("Primary") {}
                .buttonStyle(.borderedProminent)
                .tint(Color.saneAccent)

            Button("Secondary") {}
                .buttonStyle(.bordered)

            Button("Destructive") {}
                .buttonStyle(.bordered)
                .tint(.red)
        }
    }
    .padding(20)
    .frame(width: 500)
    .background(SaneGradientBackground())
}
