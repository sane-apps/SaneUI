import AppKit
import SwiftUI

// MARK: - Visual Effect Blur

/// A translucent blur effect view for macOS glass morphism.
public struct VisualEffectBlur: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context _: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Sane Brand Colors

/// Navy + teal palette used across all SaneApps backgrounds.
public enum SanePalette {
    // Dark mode: deep ocean tones
    public static let navyDeep = Color(red: 0.02, green: 0.04, blue: 0.12)
    public static let navy = Color(red: 0.04, green: 0.08, blue: 0.18)
    public static let navyMid = Color(red: 0.03, green: 0.06, blue: 0.16)
    public static let navyTeal = Color(red: 0.04, green: 0.12, blue: 0.22)
    public static let tealGlow = Color(red: 0.06, green: 0.22, blue: 0.30)
    public static let tealBright = Color(red: 0.08, green: 0.28, blue: 0.34)
    public static let tealDeep = Color(red: 0.03, green: 0.14, blue: 0.20)
    public static let cyanHint = Color(red: 0.05, green: 0.18, blue: 0.25)

    // Light mode: soft teal-blue wash
    public static let lightWash = Color(red: 0.94, green: 0.97, blue: 0.99)
    public static let lightTeal = Color(red: 0.89, green: 0.95, blue: 0.97)
    public static let lightNavy = Color(red: 0.91, green: 0.94, blue: 0.98)
    public static let lightGlow = Color(red: 0.86, green: 0.94, blue: 0.97)
    public static let lightBright = Color(red: 0.84, green: 0.93, blue: 0.96)
    public static let lightCool = Color(red: 0.93, green: 0.96, blue: 0.99)
    public static let lightSoft = Color(red: 0.92, green: 0.96, blue: 0.98)
    public static let lightWarm = Color(red: 0.90, green: 0.95, blue: 0.98)
}

// MARK: - Sane Gradient Background

/// The standard SaneApps background with living mesh gradient.
///
/// Animates by default on macOS 15+. Respects Reduce Motion.
/// Falls back to a linear gradient on macOS 14.
///
/// ```swift
/// .background(SaneGradientBackground())
/// ```
public struct SaneGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            // Layer 0: System vibrancy (dark mode depth)
            if colorScheme == .dark {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
            }

            // Layer 1: Living mesh or linear fallback
            if #available(macOS 15.0, *) {
                if reduceMotion {
                    staticMesh
                } else {
                    livingMesh
                }
            } else {
                linearFallback
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Living Mesh (Animated, macOS 15+)

    @available(macOS 15.0, *)
    private var livingMesh: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: false)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            // Multiple independent drift cycles (different speeds = organic)
            let slow = Float(sin(t / 14.0)) // 14s cycle — main breathing
            let medium = Float(sin(t / 9.0)) // 9s cycle — secondary drift
            let fast = Float(cos(t / 7.0)) // 7s cycle — subtle counter-movement

            // Drift amplitudes (subtle — don't want seasickness)
            let d1 = slow * 0.035
            let d2 = medium * 0.025
            let d3 = fast * 0.02

            MeshGradient(
                width: 4, height: 4,
                points: [
                    // Row 0: top edge
                    [0.0, 0.0], [0.33, 0.0], [0.66, 0.0], [1.0, 0.0],
                    // Row 1: upper — drifts create rolling motion
                    [0.0, 0.33], [0.35 + d1, 0.30 - d2], [0.68 - d2, 0.32 + d3], [1.0, 0.33],
                    // Row 2: lower — counter-drift for depth
                    [0.0, 0.66], [0.32 - d3, 0.65 + d1], [0.65 + d2, 0.68 - d1], [1.0, 0.66],
                    // Row 3: bottom edge
                    [0.0, 1.0], [0.33, 1.0], [0.66, 1.0], [1.0, 1.0]
                ],
                colors: colorScheme == .dark ? [
                    // Row 0: navy edge
                    SanePalette.navyDeep, SanePalette.navy, SanePalette.navyMid, SanePalette.navyDeep,
                    // Row 1: teal warmth emerges
                    SanePalette.navy, SanePalette.tealGlow, SanePalette.cyanHint, SanePalette.navyTeal,
                    // Row 2: deep teal band
                    SanePalette.navyTeal, SanePalette.cyanHint, SanePalette.tealBright, SanePalette.tealDeep,
                    // Row 3: fade back to navy
                    SanePalette.navyDeep, SanePalette.navyMid, SanePalette.tealDeep, SanePalette.navyDeep
                ] : [
                    // Row 0: clean top
                    SanePalette.lightWash, SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWash,
                    // Row 1: teal glow area
                    SanePalette.lightNavy, SanePalette.lightGlow, SanePalette.lightBright, SanePalette.lightSoft,
                    // Row 2: warm teal band
                    SanePalette.lightSoft, SanePalette.lightBright, SanePalette.lightTeal, SanePalette.lightWarm,
                    // Row 3: cool bottom
                    SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWarm, SanePalette.lightWash
                ]
            )
        }
    }

    // MARK: - Static Mesh (Reduce Motion, macOS 15+)

    @available(macOS 15.0, *)
    private var staticMesh: some View {
        MeshGradient(
            width: 4, height: 4,
            points: [
                [0.0, 0.0], [0.33, 0.0], [0.66, 0.0], [1.0, 0.0],
                [0.0, 0.33], [0.35, 0.30], [0.68, 0.32], [1.0, 0.33],
                [0.0, 0.66], [0.32, 0.65], [0.65, 0.68], [1.0, 0.66],
                [0.0, 1.0], [0.33, 1.0], [0.66, 1.0], [1.0, 1.0]
            ],
            colors: colorScheme == .dark ? [
                SanePalette.navyDeep, SanePalette.navy, SanePalette.navyMid, SanePalette.navyDeep,
                SanePalette.navy, SanePalette.tealGlow, SanePalette.cyanHint, SanePalette.navyTeal,
                SanePalette.navyTeal, SanePalette.cyanHint, SanePalette.tealBright, SanePalette.tealDeep,
                SanePalette.navyDeep, SanePalette.navyMid, SanePalette.tealDeep, SanePalette.navyDeep
            ] : [
                SanePalette.lightWash, SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWash,
                SanePalette.lightNavy, SanePalette.lightGlow, SanePalette.lightBright, SanePalette.lightSoft,
                SanePalette.lightSoft, SanePalette.lightBright, SanePalette.lightTeal, SanePalette.lightWarm,
                SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWarm, SanePalette.lightWash
            ]
        )
    }

    // MARK: - Linear Fallback (macOS 14)

    private var linearFallback: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [SanePalette.navy, SanePalette.tealDeep, SanePalette.navyDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [SanePalette.lightWash, SanePalette.lightGlow, SanePalette.lightCool],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

// MARK: - Glass Group Box Style

/// A glass morphism style for SwiftUI GroupBox.
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
                    colorScheme == .dark ? Color.white.opacity(0.12) : Color.saneAccent.opacity(0.15),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Previews

#Preview("Living Mesh Background") {
    VStack(spacing: 16) {
        Text("Navy + Teal Living Mesh")
            .font(.title2.bold())
            .foregroundStyle(.white)

        CompactSection("Browse Icons") {
            CompactRow("Opens as") {
                Text("Icon Panel")
                    .foregroundStyle(.secondary)
            }
            CompactDivider()
            CompactRow("Shortcut") {
                Text("⌘⇧Space")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)

        CompactSection("Startup") {
            CompactToggle(label: "Start at login", isOn: .constant(true))
            CompactDivider()
            CompactToggle(label: "Show Dock icon", isOn: .constant(false))
        }
        .padding(.horizontal, 20)
    }
    .frame(width: 500, height: 450)
    .background(SaneGradientBackground())
}
