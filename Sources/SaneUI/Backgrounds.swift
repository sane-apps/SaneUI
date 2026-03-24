import SwiftUI
#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

// MARK: - Visual Effect Blur

/// A translucent blur effect view for macOS glass morphism.
#if canImport(AppKit)
    public struct VisualEffectBlur: NSViewRepresentable {
        public let material: NSVisualEffectView.Material
        public let blendingMode: NSVisualEffectView.BlendingMode
        public let state: NSVisualEffectView.State
        public let isEmphasized: Bool

        public init(
            material: NSVisualEffectView.Material = .hudWindow,
            blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
            state: NSVisualEffectView.State = .active,
            isEmphasized: Bool = false
        ) {
            self.material = material
            self.blendingMode = blendingMode
            self.state = state
            self.isEmphasized = isEmphasized
        }

        public func makeNSView(context _: Context) -> NSVisualEffectView {
            let view = NSVisualEffectView()
            view.material = material
            view.blendingMode = blendingMode
            view.state = state
            view.isEmphasized = isEmphasized
            return view
        }

        public func updateNSView(_ nsView: NSVisualEffectView, context _: Context) {
            nsView.material = material
            nsView.blendingMode = blendingMode
            nsView.state = state
            nsView.isEmphasized = isEmphasized
        }
    }
#elseif canImport(UIKit)
    public struct VisualEffectBlur: UIViewRepresentable {
        public init() {}

        public func makeUIView(context _: Context) -> UIVisualEffectView {
            UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        }

        public func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
            uiView.effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        }
    }
#endif

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
    public static let tealGlowPanel = Color(red: 0.055, green: 0.20, blue: 0.28)
    public static let tealBrightPanel = Color(red: 0.072, green: 0.245, blue: 0.305)
    public static let cyanHintPanel = Color(red: 0.045, green: 0.165, blue: 0.225)

    // Light mode: soft teal-blue wash
    public static let lightWash = Color(red: 0.94, green: 0.97, blue: 0.99)
    public static let lightTeal = Color(red: 0.89, green: 0.95, blue: 0.97)
    public static let lightNavy = Color(red: 0.91, green: 0.94, blue: 0.98)
    public static let lightGlow = Color(red: 0.86, green: 0.94, blue: 0.97)
    public static let lightBright = Color(red: 0.84, green: 0.93, blue: 0.96)
    public static let lightCool = Color(red: 0.93, green: 0.96, blue: 0.99)
    public static let lightSoft = Color(red: 0.92, green: 0.96, blue: 0.98)
    public static let lightWarm = Color(red: 0.90, green: 0.95, blue: 0.98)
    public static let lightGlowPanel = Color(red: 0.88, green: 0.945, blue: 0.968)
    public static let lightBrightPanel = Color(red: 0.855, green: 0.935, blue: 0.958)
    public static let lightTealPanel = Color(red: 0.90, green: 0.952, blue: 0.972)
}

public enum SaneGradientBackgroundStyle: Sendable {
    case standard
    case panel
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
    private let style: SaneGradientBackgroundStyle

    public init(style: SaneGradientBackgroundStyle = .standard) {
        self.style = style
    }

    public var body: some View {
        ZStack {
            // Layer 0: System vibrancy (dark mode depth)
            if colorScheme == .dark {
                #if os(macOS)
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                #else
                    VisualEffectBlur()
                #endif
            }

            // Layer 1: Living mesh or linear fallback
            if #available(iOS 18.0, macOS 15.0, *) {
                if Self.usesAnimatedMesh(style: style, reduceMotion: reduceMotion) {
                    livingMesh
                } else {
                    staticMesh
                }
            } else {
                linearFallback
            }
        }
        .opacity(Self.meshOpacity(for: style))
        .ignoresSafeArea()
    }

    // MARK: - Living Mesh (Animated, macOS 15+)

    @available(iOS 18.0, macOS 15.0, *)
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
                colors: meshColors
            )
        }
    }

    // MARK: - Static Mesh (Reduce Motion, macOS 15+)

    @available(iOS 18.0, macOS 15.0, *)
    private var staticMesh: some View {
        MeshGradient(
            width: 4, height: 4,
            points: [
                [0.0, 0.0], [0.33, 0.0], [0.66, 0.0], [1.0, 0.0],
                [0.0, 0.33], [0.35, 0.30], [0.68, 0.32], [1.0, 0.33],
                [0.0, 0.66], [0.32, 0.65], [0.65, 0.68], [1.0, 0.66],
                [0.0, 1.0], [0.33, 1.0], [0.66, 1.0], [1.0, 1.0]
            ],
            colors: meshColors
        )
    }

    // MARK: - Linear Fallback (macOS 14)

    private var linearFallback: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: style == .panel
                        ? [SanePalette.navy, SanePalette.tealGlowPanel, SanePalette.navyDeep]
                        : [SanePalette.navy, SanePalette.tealDeep, SanePalette.navyDeep],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: style == .panel
                        ? [SanePalette.lightWash, SanePalette.lightGlowPanel, SanePalette.lightCool]
                        : [SanePalette.lightWash, SanePalette.lightGlow, SanePalette.lightCool],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var meshColors: [Color] {
        colorScheme == .dark ? darkMeshColors : lightMeshColors
    }

    private var darkMeshColors: [Color] {
        switch style {
        case .standard:
            [
                SanePalette.navyDeep, SanePalette.navy, SanePalette.navyMid, SanePalette.navyDeep,
                SanePalette.navy, SanePalette.tealGlow, SanePalette.cyanHint, SanePalette.navyTeal,
                SanePalette.navyTeal, SanePalette.cyanHint, SanePalette.tealBright, SanePalette.tealDeep,
                SanePalette.navyDeep, SanePalette.navyMid, SanePalette.tealDeep, SanePalette.navyDeep
            ]
        case .panel:
            [
                SanePalette.navyDeep, SanePalette.navy, SanePalette.navyMid, SanePalette.navyDeep,
                SanePalette.navy, SanePalette.tealGlowPanel, SanePalette.cyanHintPanel, SanePalette.navyTeal,
                SanePalette.navyTeal, SanePalette.cyanHintPanel, SanePalette.tealBrightPanel, SanePalette.tealDeep,
                SanePalette.navyDeep, SanePalette.navyMid, SanePalette.tealDeep, SanePalette.navyDeep
            ]
        }
    }

    private var lightMeshColors: [Color] {
        switch style {
        case .standard:
            [
                SanePalette.lightWash, SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWash,
                SanePalette.lightNavy, SanePalette.lightGlow, SanePalette.lightBright, SanePalette.lightSoft,
                SanePalette.lightSoft, SanePalette.lightBright, SanePalette.lightTeal, SanePalette.lightWarm,
                SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWarm, SanePalette.lightWash
            ]
        case .panel:
            [
                SanePalette.lightWash, SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWash,
                SanePalette.lightNavy, SanePalette.lightGlowPanel, SanePalette.lightBrightPanel, SanePalette.lightSoft,
                SanePalette.lightSoft, SanePalette.lightBrightPanel, SanePalette.lightTealPanel, SanePalette.lightWarm,
                SanePalette.lightCool, SanePalette.lightNavy, SanePalette.lightWarm, SanePalette.lightWash
            ]
        }
    }

    internal nonisolated static func meshOpacity(for style: SaneGradientBackgroundStyle) -> Double {
        switch style {
        case .standard:
            1.0
        case .panel:
            0.9
        }
    }

    internal nonisolated static func usesAnimatedMesh(
        style: SaneGradientBackgroundStyle,
        reduceMotion: Bool
    ) -> Bool {
        switch style {
        case .standard:
            !reduceMotion
        case .panel:
            false
        }
    }
}

// MARK: - Shared Glass Chrome

/// A rounded glass surface used by settings sections and panels across SaneApps.
public struct SaneGlassRoundedBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    var tint: Color
    var edgeTint: Color?
    var tintStrength: Double
    var glowOpacity: Double
    var interactive: Bool
    var shadowOpacity: Double
    var shadowRadius: CGFloat
    var shadowY: CGFloat

    public init(
        cornerRadius: CGFloat,
        tint: Color = SanePanelChrome.accentStart,
        edgeTint: Color? = nil,
        tintStrength: Double = 0.14,
        glowOpacity: Double = 0.0,
        interactive: Bool = false,
        shadowOpacity: Double = 0.16,
        shadowRadius: CGFloat = 10,
        shadowY: CGFloat = 4
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.edgeTint = edgeTint
        self.tintStrength = tintStrength
        self.glowOpacity = glowOpacity
        self.interactive = interactive
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
    }

    public var body: some View {
        ZStack {
            glassBase

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.14 : 0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(colorScheme == .dark ? tintStrength : tintStrength * 0.65),
                            SanePanelChrome.accentEnd.opacity(colorScheme == .dark ? tintStrength * 0.42 : tintStrength * 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.24 : 0.14),
                            resolvedEdgeTint.opacity(colorScheme == .dark ? 0.40 : 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? shadowOpacity : shadowOpacity * 0.55),
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
        .shadow(
            color: resolvedEdgeTint.opacity(colorScheme == .dark ? glowOpacity : glowOpacity * 0.45),
            radius: shadowRadius,
            x: 0,
            y: 1
        )
    }

    @ViewBuilder
    private var glassBase: some View {
        #if swift(>=6.2)
            if #available(macOS 26.0, *) {
                if interactive {
                    Color.clear.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
                } else {
                    Color.clear.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                }
            } else {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .opacity(colorScheme == .dark ? 0.88 : 0.74)
            }
        #else
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(colorScheme == .dark ? 0.88 : 0.74)
        #endif
    }

    private var resolvedEdgeTint: Color { edgeTint ?? tint }
}

/// A capsule glass surface used by shared controls.
public struct SaneGlassCapsuleBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var tint: Color
    var edgeTint: Color?
    var tintStrength: Double
    var glowOpacity: Double
    var interactive: Bool
    var shadowOpacity: Double
    var shadowRadius: CGFloat
    var shadowY: CGFloat

    public init(
        tint: Color = SanePanelChrome.accentStart,
        edgeTint: Color? = nil,
        tintStrength: Double = 0.26,
        glowOpacity: Double = 0.0,
        interactive: Bool = true,
        shadowOpacity: Double = 0.18,
        shadowRadius: CGFloat = 8,
        shadowY: CGFloat = 3
    ) {
        self.tint = tint
        self.edgeTint = edgeTint
        self.tintStrength = tintStrength
        self.glowOpacity = glowOpacity
        self.interactive = interactive
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowY = shadowY
    }

    public var body: some View {
        ZStack {
            glassBase

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.10),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(colorScheme == .dark ? tintStrength : tintStrength * 0.70),
                            SanePanelChrome.accentEnd.opacity(colorScheme == .dark ? tintStrength * 0.48 : tintStrength * 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.32 : 0.18),
                            resolvedEdgeTint.opacity(colorScheme == .dark ? 0.50 : 0.30)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? shadowOpacity : shadowOpacity * 0.55),
            radius: shadowRadius,
            x: 0,
            y: shadowY
        )
        .shadow(
            color: resolvedEdgeTint.opacity(colorScheme == .dark ? glowOpacity : glowOpacity * 0.45),
            radius: shadowRadius,
            x: 0,
            y: 1
        )
    }

    @ViewBuilder
    private var glassBase: some View {
        #if swift(>=6.2)
            if #available(macOS 26.0, *) {
                if interactive {
                    Color.clear.glassEffect(.regular.interactive(), in: .capsule)
                } else {
                    Color.clear.glassEffect(.regular, in: .capsule)
                }
            } else {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .opacity(colorScheme == .dark ? 0.90 : 0.76)
            }
        #else
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(colorScheme == .dark ? 0.90 : 0.76)
        #endif
    }

    private var resolvedEdgeTint: Color { edgeTint ?? tint }
}

/// A circular glass surface used by compact icon controls.
public struct SaneGlassCircleBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var tint: Color
    var edgeTint: Color?
    var tintStrength: Double
    var glowOpacity: Double
    var interactive: Bool

    public init(
        tint: Color = SanePanelChrome.accentStart,
        edgeTint: Color? = nil,
        tintStrength: Double = 0.24,
        glowOpacity: Double = 0.0,
        interactive: Bool = true
    ) {
        self.tint = tint
        self.edgeTint = edgeTint
        self.tintStrength = tintStrength
        self.glowOpacity = glowOpacity
        self.interactive = interactive
    }

    public var body: some View {
        ZStack {
            glassBase

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.18 : 0.10),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(colorScheme == .dark ? tintStrength : tintStrength * 0.70),
                            SanePanelChrome.accentEnd.opacity(colorScheme == .dark ? tintStrength * 0.42 : tintStrength * 0.24)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.30 : 0.18),
                            resolvedEdgeTint.opacity(colorScheme == .dark ? 0.48 : 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.16 : 0.08),
            radius: 7,
            x: 0,
            y: 3
        )
        .shadow(
            color: resolvedEdgeTint.opacity(colorScheme == .dark ? glowOpacity : glowOpacity * 0.45),
            radius: 7,
            x: 0,
            y: 1
        )
    }

    @ViewBuilder
    private var glassBase: some View {
        #if swift(>=6.2)
            if #available(macOS 26.0, *) {
                if interactive {
                    Color.clear.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 999))
                } else {
                    Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 999))
                }
            } else {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                    .opacity(colorScheme == .dark ? 0.90 : 0.76)
            }
        #else
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(colorScheme == .dark ? 0.90 : 0.76)
        #endif
    }

    private var resolvedEdgeTint: Color { edgeTint ?? tint }
}

public struct SanePressablePlainStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.955 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .saturation(configuration.isPressed ? 1.18 : 1)
            .contrast(configuration.isPressed ? 1.06 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.spring(response: 0.18, dampingFraction: 0.74), value: configuration.isPressed)
    }
}

// MARK: - Glass Group Box Style

/// A glass morphism style for SwiftUI GroupBox.
public struct GlassGroupBoxStyle: GroupBoxStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            configuration.label
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            configuration.content
        }
        .padding(16)
        .background(
            SaneGlassRoundedBackground(
                cornerRadius: 12,
                tint: SanePanelChrome.panelTint,
                tintStrength: 0.12,
                shadowOpacity: 0.12,
                shadowRadius: 8,
                shadowY: 3
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
