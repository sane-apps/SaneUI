import SwiftUI
#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// Canonical GitHub Sponsors destination for SaneApps donate buttons.
public enum SaneDonation {
    public static let githubSponsorsURL = URL(string: "https://github.com/sponsors/MrSaneApps")!
}

/// Persistent Donate control for open-source apps. Always opens GitHub Sponsors.
public struct SaneStickyDonateButton: View {
    private let url: URL

    public init(url: URL = SaneDonation.githubSponsorsURL) {
        self.url = url
    }

    public var body: some View {
        Button {
            SanePlatform.open(url)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("Donate")
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
        .accessibilityIdentifier("sticky-donate")
        .accessibilityLabel("Donate")
        .help("Donate on GitHub Sponsors")
    }
}

public extension View {
    /// Pins a working Donate button to the bottom-trailing corner of the live app.
    func saneStickyDonate(
        url: URL = SaneDonation.githubSponsorsURL,
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
