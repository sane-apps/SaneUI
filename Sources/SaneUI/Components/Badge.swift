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
        Group {
            switch style {
            case .primary:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)

            case .secondary:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.bordered)

            case .destructive:
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
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
                .tint(.teal)

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
