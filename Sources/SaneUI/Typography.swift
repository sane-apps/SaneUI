import SwiftUI

/// Shared type tokens for settings and customer-facing chrome.
///
/// Floor: **14pt bright white**. Never use `.secondary`, gray, or dim helper opacity
/// for settings copy. Flat/legacy glass is only a material fallback — type rules stay.
public enum SaneTypography {
    public static let bodySize: CGFloat = 14
    public static let sectionSize: CGFloat = 15
    public static let titleSize: CGFloat = 17

    public static let body = Font.system(size: bodySize, weight: .medium)
    public static let label = Font.system(size: bodySize, weight: .semibold)
    public static let section = Font.system(size: sectionSize, weight: .semibold)
    public static let title = Font.system(size: titleSize, weight: .bold)
    public static let mono = Font.system(size: bodySize, design: .monospaced)

    /// Bright white for all settings / chrome copy.
    public static let text = Color.white
}
