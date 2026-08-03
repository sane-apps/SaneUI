import SwiftUI

/// Shared type tokens for settings and customer-facing chrome.
///
/// Floor: **16pt bright white** for row/body copy. Never use `.secondary`, gray,
/// or dim helper opacity for settings copy. Flat/legacy glass is only a material
/// fallback — type rules stay.
///
/// Why 16 (not 14): macOS Button/`controlSize` environments still visually crush
/// absolute 14pt row labels next to sidebar chrome. 16pt semibold is the readable
/// customer floor across CompactRow / CompactToggle / helpers.
public enum SaneTypography {
    public static let bodySize: CGFloat = 16
    public static let sectionSize: CGFloat = 17
    public static let titleSize: CGFloat = 20

    public static let body = Font.system(size: bodySize, weight: .medium)
    public static let label = Font.system(size: bodySize, weight: .semibold)
    public static let section = Font.system(size: sectionSize, weight: .semibold)
    public static let title = Font.system(size: titleSize, weight: .bold)
    public static let mono = Font.system(size: bodySize, design: .monospaced)

    /// Bright white for all settings / chrome copy.
    public static let text = Color.white
}
