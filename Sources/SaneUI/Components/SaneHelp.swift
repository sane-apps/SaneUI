import SwiftUI

/// Shared help treatment for customer-facing SaneApps controls.
///
/// The hover behavior intentionally uses Apple's native help API so macOS owns
/// tooltip placement, timing, text rendering, and accessibility integration.
public struct SaneHelpModifier: ViewModifier {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public func body(content: Content) -> some View {
        content
            .help(text)
            .accessibilityHint(text)
    }
}

public extension View {
    /// Adds native Apple hover help and the matching accessibility hint.
    ///
    /// Use this for short, customer-facing explanations of buttons, badges,
    /// segmented choices, toggles, and compact actions. Put high-importance
    /// explanations in visible inline copy as well; don't rely on hover alone.
    func saneHelp(_ text: String) -> some View {
        modifier(SaneHelpModifier(text))
    }
}

/// Visible explanatory copy for settings whose behavior should be clear without hover.
public struct SaneInlineHelp: View {
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.94))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(text)
    }
}
