import SwiftUI

/// Shared type tokens for settings and customer-facing chrome.
///
/// Floor: **13pt bright white** for row/body/sidebar copy (matches global AGENTS).
/// Never use `.secondary`, gray, or dim helper opacity for settings copy.
/// Flat/legacy glass is only a material fallback — type rules stay.
///
/// Why 13 (not 18): 18pt semibold read chunky / juvenile next to macOS controls
/// and dense product UI. 13pt medium/semibold stays readable and adult without
/// blowing row height. Titles stay a step up for hierarchy.
public enum SaneTypography {
    public static let bodySize: CGFloat = 13
    public static let sectionSize: CGFloat = 13
    public static let titleSize: CGFloat = 17

    public static let body = Font.system(size: bodySize, weight: .medium)
    public static let label = Font.system(size: bodySize, weight: .semibold)
    public static let section = Font.system(size: sectionSize, weight: .semibold)
    public static let title = Font.system(size: titleSize, weight: .bold)
    public static let mono = Font.system(size: bodySize, design: .monospaced)

    /// Bright white for all settings / chrome copy.
    public static let text = Color.white
}
