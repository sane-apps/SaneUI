import Foundation

enum SaneRuntimeEnvironment {
    static func isTestRun(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        processName: String = ProcessInfo.processInfo.processName,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier,
        bundlePath: String = Bundle.main.bundlePath
    ) -> Bool {
        if environment["XCTestConfigurationFilePath"] != nil { return true }
        if environment["XCTestSessionIdentifier"] != nil { return true }
        if processName == "xctest" { return true }
        if bundlePath.hasSuffix(".xctest") { return true }
        if let bundleIdentifier {
            if bundleIdentifier.hasSuffix("Tests") { return true }
            if bundleIdentifier.contains("xctest") { return true }
        }
        return false
    }
}
