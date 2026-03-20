#if os(macOS)
import Foundation

public enum SaneInstallLocation {
    public static func isInApplicationsDirectory(_ appPath: String, homeDirectory: String = NSHomeDirectory()) -> Bool {
        let normalizedPath = (appPath as NSString).standardizingPath
        let systemApplications = ("/Applications" as NSString).standardizingPath
        let userApplications = ((homeDirectory as NSString).appendingPathComponent("Applications") as NSString).standardizingPath

        if normalizedPath == systemApplications || normalizedPath.hasPrefix(systemApplications + "/") {
            return true
        }

        if normalizedPath == userApplications || normalizedPath.hasPrefix(userApplications + "/") {
            return true
        }

        return false
    }
}
#endif
