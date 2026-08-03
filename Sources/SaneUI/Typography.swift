import SwiftUI

/// Shared type tokens for settings and customer-facing chrome.
///
/// Floor: **18pt bright white** for row/body/sidebar copy. Never use `.secondary`,
/// gray, or dim helper opacity for settings copy. Flat/legacy glass is only a
/// material fallback — type rules stay.
///
/// Why 18: absolute 14–16pt still read small next to macOS toggles and section
/// chrome in a 720pt settings window. 18pt semibold is the readable customer floor.
public enum SaneTypography {
    public static let bodySize: CGFloat = 18
    public static let sectionSize: CGFloat = 18
    public static let titleSize: CGFloat = 22

    public static let body = Font.system(size: bodySize, weight: .medium)
    public static let label = Font.system(size: bodySize, weight: .semibold)
    public static let section = Font.system(size: sectionSize, weight: .semibold)
    public static let title = Font.system(size: titleSize, weight: .bold)
    public static let mono = Font.system(size: bodySize, design: .monospaced)

    /// Bright white for all settings / chrome copy.
    public static let text = Color.white
}
