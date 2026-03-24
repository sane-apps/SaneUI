import SwiftUI

// MARK: - Semantic Colors

/// Semantic color definitions for SaneApps
public enum SaneColors {
    /// Primary accent color (teal-blue, SaneUI standard)
    public static let accent = Color.saneAccent

    /// Success state color
    public static let success = Color.green

    /// Danger/destructive action color
    public static let danger = Color.red

    /// Warning state color
    public static let warning = Color.orange

    /// Informational color
    public static let info = Color.blue
}

// MARK: - Color Extensions

public extension Color {
    /// Success state color for SaneApps
    static let saneSuccess = Color.green

    /// Danger/destructive action color for SaneApps
    static let saneDanger = Color.red

    /// Warning state color for SaneApps
    static let saneWarning = Color.orange

    /// Primary accent color for SaneApps
    static let saneAccent = Color(red: 0.05, green: 0.64, blue: 0.78)
    /// Deeper teal accent for gradients and hover states
    static let saneAccentDeep = Color(red: 0.06, green: 0.45, blue: 0.56)
    /// Brighter accent endpoint for premium gradients
    static let saneAccentSoft = Color(red: 0.36, green: 0.86, blue: 0.95)
}

// MARK: - Shared Panel Chrome

/// Shared chrome tokens for compact utility surfaces across SaneApps.
public enum SanePanelChrome {
    public static let accentStart = Color(red: 0.22, green: 0.45, blue: 1.00)
    public static let accentEnd = Color(red: 0.10, green: 0.24, blue: 0.78)
    public static let accentHighlight = Color(red: 0.57, green: 0.76, blue: 1.00)
    public static let accentTeal = Color(red: 0.32, green: 0.88, blue: 0.94)
    public static let controlNavy = Color(red: 0.11, green: 0.20, blue: 0.46)
    public static let controlNavyDeep = Color(red: 0.07, green: 0.14, blue: 0.32)
    public static let panelTint = Color(red: 0.14, green: 0.26, blue: 0.56)

    public static let activeControlFill = accentStart
    public static let utilityFill = controlNavyDeep
    public static let softSurfaceFill = panelTint.opacity(0.10)
    public static let targetControlFill = accentTeal
    public static let controlStroke = Color.white.opacity(0.20)
    public static let rowStroke = Color.white.opacity(0.12)
    public static let controlShadow = Color.black.opacity(0.20)
}

// MARK: - Adaptive Colors

/// Colors that adapt to light/dark mode
public struct AdaptiveColors: Sendable {
    let colorScheme: ColorScheme

    public init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }

    /// Background fill for cards/sections
    public var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.white
    }

    /// Border color for cards/sections
    public var cardBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.saneAccent.opacity(0.18)
    }

    /// Shadow color for cards/sections
    public var cardShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.15) : Color.saneAccentDeep.opacity(0.12)
    }

    /// Shadow radius for cards/sections
    public var shadowRadius: CGFloat {
        colorScheme == .dark ? 8 : 6
    }
}

// MARK: - Environment Key

private struct AdaptiveColorsKey: EnvironmentKey {
    static let defaultValue = AdaptiveColors(colorScheme: .dark)
}

public extension EnvironmentValues {
    var adaptiveColors: AdaptiveColors {
        get { self[AdaptiveColorsKey.self] }
        set { self[AdaptiveColorsKey.self] = newValue }
    }
}
