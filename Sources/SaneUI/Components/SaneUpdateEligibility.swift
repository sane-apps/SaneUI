#if os(macOS)
import Foundation

public enum SaneUpdateEligibility: Equatable, Sendable {
    case eligible
    case nonReleaseBundle
    case notInstalledInApplications

    public var canUseInAppUpdates: Bool {
        self == .eligible
    }

    public var userFacingStatus: String {
        switch self {
        case .eligible:
            "Updates are available in this app."
        case .nonReleaseBundle:
            "Updates are not available for this build."
        case .notInstalledInApplications:
            "Updates are available after the app is opened from your Applications folder."
        }
    }

    public static func resolve(
        bundleIdentifier: String?,
        releaseBundleIdentifier: String,
        bundlePath: String,
        homeDirectory: String = NSHomeDirectory()
    ) -> Self {
        guard bundleIdentifier == releaseBundleIdentifier else {
            return .nonReleaseBundle
        }

        guard SaneInstallLocation.isInApplicationsDirectory(bundlePath, homeDirectory: homeDirectory) else {
            return .notInstalledInApplications
        }

        return .eligible
    }
}
#endif
