#if os(macOS)
import AppKit
import Foundation

public enum SaneApplicationMover {
    public struct Prompt: Sendable {
        public let messageText: String
        public let informativeText: String
        public let moveButtonTitle: String
        public let cancelButtonTitle: String

        public init(
            messageText: String,
            informativeText: String,
            moveButtonTitle: String,
            cancelButtonTitle: String
        ) {
            self.messageText = messageText
            self.informativeText = informativeText
            self.moveButtonTitle = moveButtonTitle
            self.cancelButtonTitle = cancelButtonTitle
        }
    }

    public struct DestinationCandidate: Equatable, Sendable {
        public let url: URL
        public let isUserApplicationsFolder: Bool
    }

    public static let skipEnvironmentKey = "SANEAPPS_SKIP_MOVE_TO_APPLICATIONS"
    public static let skipArgument = "--sane-skip-app-move"

    public static func shouldSkipMove(environment: [String: String] = ProcessInfo.processInfo.environment, arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        environment[skipEnvironmentKey] == "1" || arguments.contains(skipArgument)
    }

    public static func destinationCandidates(
        appBundleName: String,
        homeDirectory: String = NSHomeDirectory(),
        systemApplicationsDirectory: String = "/Applications"
    ) -> [DestinationCandidate] {
        let systemApplications = URL(fileURLWithPath: systemApplicationsDirectory, isDirectory: true)
        let userApplications = URL(fileURLWithPath: homeDirectory, isDirectory: true)
            .appendingPathComponent("Applications", isDirectory: true)

        return [
            DestinationCandidate(
                url: systemApplications.appendingPathComponent(appBundleName, isDirectory: true),
                isUserApplicationsFolder: false
            ),
            DestinationCandidate(
                url: userApplications.appendingPathComponent(appBundleName, isDirectory: true),
                isUserApplicationsFolder: true
            )
        ]
    }

    @MainActor
    @discardableResult
    public static func moveToApplicationsFolderIfNeeded(prompt: Prompt) -> Bool {
        guard !shouldSkipMove() else { return false }

        let sourceURL = Bundle.main.bundleURL
        let appBundleName = sourceURL.lastPathComponent
        guard !SaneInstallLocation.isInApplicationsDirectory(sourceURL.path) else { return false }

        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = prompt.messageText
        alert.informativeText = prompt.informativeText.replacingOccurrences(of: "{appName}", with: appBundleName)
        alert.alertStyle = .informational
        alert.addButton(withTitle: prompt.moveButtonTitle)
        alert.addButton(withTitle: prompt.cancelButtonTitle)
        guard alert.runModal() == .alertFirstButtonReturn else { return false }

        guard let destinationURL = copyAppBundleToInstalledLocation(sourceURL: sourceURL, appBundleName: appBundleName) else {
            showInstallFailedAlert(appBundleName: appBundleName)
            return false
        }

        relaunchInstalledApp(at: destinationURL, appBundleName: appBundleName)
        return true
    }

    static func copyAppBundleToInstalledLocation(
        sourceURL: URL,
        appBundleName: String,
        fileManager: FileManager = .default,
        homeDirectory: String = NSHomeDirectory(),
        systemApplicationsDirectory: String = "/Applications"
    ) -> URL? {
        for candidate in destinationCandidates(
            appBundleName: appBundleName,
            homeDirectory: homeDirectory,
            systemApplicationsDirectory: systemApplicationsDirectory
        ) {
            if candidate.isUserApplicationsFolder {
                do {
                    try fileManager.createDirectory(
                        at: candidate.url.deletingLastPathComponent(),
                        withIntermediateDirectories: true
                    )
                } catch {
                    continue
                }
            }

            do {
                try copyAppBundle(sourceURL, to: candidate.url, appBundleName: appBundleName, fileManager: fileManager)
                guard fileManager.fileExists(atPath: candidate.url.path) else { continue }
                return candidate.url
            } catch {
                continue
            }
        }

        return nil
    }

    private static func copyAppBundle(_ sourceURL: URL, to destinationURL: URL, appBundleName: String, fileManager: FileManager) throws {
        let parentURL = destinationURL.deletingLastPathComponent()
        let uniqueSuffix = UUID().uuidString
        let stagingURL = parentURL.appendingPathComponent(".\(appBundleName).installing-\(uniqueSuffix)", isDirectory: true)
        let backupURL = parentURL.appendingPathComponent(".\(appBundleName).previous-\(uniqueSuffix)", isDirectory: true)
        var movedExistingToBackup = false

        try? fileManager.removeItem(at: stagingURL)
        try fileManager.copyItem(at: sourceURL, to: stagingURL)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.moveItem(at: destinationURL, to: backupURL)
                movedExistingToBackup = true
            }

            try fileManager.moveItem(at: stagingURL, to: destinationURL)

            if movedExistingToBackup {
                try? fileManager.trashItem(at: backupURL, resultingItemURL: nil)
            }
        } catch {
            if movedExistingToBackup, !fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.moveItem(at: backupURL, to: destinationURL)
            }
            try? fileManager.removeItem(at: stagingURL)
            throw error
        }
    }

    @MainActor
    private static func relaunchInstalledApp(at destinationURL: URL, appBundleName: String) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.arguments = [skipArgument]

        NSWorkspace.shared.openApplication(at: destinationURL, configuration: configuration) { _, error in
            Task { @MainActor in
                if error == nil {
                    NSApp.terminate(nil)
                } else {
                    showRelaunchFailedAlert(appBundleName: appBundleName, destinationURL: destinationURL)
                }
            }
        }
    }

    @MainActor
    private static func showInstallFailedAlert(appBundleName: String) {
        let alert = NSAlert()
        alert.messageText = "Could Not Move \(appBundleName)"
        alert.informativeText = "Move \(appBundleName) to your Applications folder manually, then open it from there before checking for updates."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @MainActor
    private static func showRelaunchFailedAlert(appBundleName: String, destinationURL: URL) {
        let alert = NSAlert()
        alert.messageText = "\(appBundleName) Was Moved"
        alert.informativeText = "Open \(destinationURL.path) before checking for updates."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
#endif
