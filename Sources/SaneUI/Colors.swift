import SwiftUI

// MARK: - Semantic Colors

/// Semantic color definitions for SaneApps
public enum SaneColors {
    /// Primary accent color (teal)
    public static let accent = Color.teal

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
    static let saneAccent = Color.teal
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
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.teal.opacity(0.15)
    }

    /// Shadow color for cards/sections
    public var cardShadow: Color {
        colorScheme == .dark ? Color.black.opacity(0.15) : Color.teal.opacity(0.08)
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
