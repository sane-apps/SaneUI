import Foundation

/// Optional copy for the direct-download support link.
/// App Store and Setapp builds leave `current` unset, so the shared library
/// ships no support-link title or destination.
public struct SaneDirectSupportCopy: Equatable, Sendable {
    public var buttonTitle: String
    public var buttonHelp: String
    public var accessibilityLabel: String
    public var destinationURL: URL
    public var aboutRowTitle: String
    public var freeAppTitle: String
    public var freeAppDetail: String
    public var welcomeIncludedDetail: String
    public var expiredOpenSourceDetail: String
    public var expiredCardTitle: String
    public var expiredCardSubtitle: String

    public init(
        buttonTitle: String,
        buttonHelp: String,
        accessibilityLabel: String,
        destinationURL: URL,
        aboutRowTitle: String,
        freeAppTitle: String,
        freeAppDetail: String,
        welcomeIncludedDetail: String,
        expiredOpenSourceDetail: String,
        expiredCardTitle: String,
        expiredCardSubtitle: String
    ) {
        self.buttonTitle = buttonTitle
        self.buttonHelp = buttonHelp
        self.accessibilityLabel = accessibilityLabel
        self.destinationURL = destinationURL
        self.aboutRowTitle = aboutRowTitle
        self.freeAppTitle = freeAppTitle
        self.freeAppDetail = freeAppDetail
        self.welcomeIncludedDetail = welcomeIncludedDetail
        self.expiredOpenSourceDetail = expiredOpenSourceDetail
        self.expiredCardTitle = expiredCardTitle
        self.expiredCardSubtitle = expiredCardSubtitle
    }

    @MainActor public static var current: SaneDirectSupportCopy?
}
