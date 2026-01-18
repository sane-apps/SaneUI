import SwiftUI
import AppKit

// MARK: - Visual Effect Blur

/// A translucent blur effect view for macOS glass morphism.
///
/// Use with `.hudWindow` material for dark mode glass effects.
///
/// ```swift
/// VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
/// ```
public struct VisualEffectBlur: NSViewRepresentable {
    /// The material type for the blur effect
    public let material: NSVisualEffectView.Material

    /// The blending mode for the blur
    public let blendingMode: NSVisualEffectView.BlendingMode

    /// Creates a new visual effect blur
    /// - Parameters:
    ///   - material: The material type (default: `.hudWindow`)
    ///   - blendingMode: The blending mode (default: `.behindWindow`)
    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Sane Gradient Background

/// The standard SaneApps gradient background with glass morphism effect.
///
/// Automatically adapts to light and dark color schemes.
///
/// ```swift
/// ZStack {
///     SaneGradientBackground()
///     // Your content
/// }
/// ```
public struct SaneGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        ZStack {
            if colorScheme == .dark {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                LinearGradient(
                    colors: [
                        Color.teal.opacity(0.08),
                        Color.blue.opacity(0.05),
                        Color.teal.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.98, blue: 0.99),
                        Color(red: 0.92, green: 0.96, blue: 0.98),
                        Color(red: 0.94, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Group Box Style

/// A glass morphism style for SwiftUI GroupBox.
///
/// ```swift
/// GroupBox {
///     // content
/// }
/// .groupBoxStyle(GlassGroupBoxStyle())
/// ```
public struct GlassGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.headline)

            configuration.content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? .ultraThinMaterial : .regularMaterial)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    colorScheme == .dark ? Color.white.opacity(0.12) : Color.teal.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Preview

#Preview("Backgrounds") {
    VStack(spacing: 20) {
        Text("SaneGradientBackground")
            .font(.headline)
            .foregroundStyle(.secondary)

        GroupBox("Glass GroupBox") {
            Text("Content inside glass morphism")
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .padding()
    }
    .frame(width: 400, height: 300)
    .background(SaneGradientBackground())
}
