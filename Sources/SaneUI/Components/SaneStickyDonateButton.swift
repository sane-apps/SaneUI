import SwiftUI
#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Support link for direct-download builds. Titles and the destination come from
/// `SaneDirectSupportCopy.current`, which App Store builds leave unset.
public struct SaneStickyDonateButton: View {
    private let urlOverride: URL?
    private let titleOverride: String?
    private let helpOverride: String?
    private let accessibilityOverride: String?

    public init(
        url: URL? = nil,
        title: String? = nil,
        helpText: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        urlOverride = url
        titleOverride = title
        helpOverride = helpText
        accessibilityOverride = accessibilityLabel
    }

    public var body: some View {
        let copy = SaneDirectSupportCopy.current
        let url = urlOverride ?? copy?.destinationURL ?? URL(string: "about:blank")!
        let title = titleOverride ?? copy?.buttonTitle ?? ""
        let helpText = helpOverride ?? copy?.buttonHelp ?? ""
        let accessibility = accessibilityOverride ?? copy?.accessibilityLabel ?? title

        Button {
            SanePlatform.open(url)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.saneAccent)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.28), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("sticky-support")
        .accessibilityLabel(accessibility)
        .help(helpText)
    }
}

public extension View {
    /// Pins the direct-download support link to the bottom-trailing corner.
    func saneStickyDonate(
        url: URL? = nil,
        bottomPadding: CGFloat = 16,
        trailingPadding: CGFloat = 16
    ) -> some View {
        overlay(alignment: .bottomTrailing) {
            SaneStickyDonateButton(url: url)
                .padding(.trailing, trailingPadding)
                .padding(.bottom, bottomPadding)
        }
    }
}
