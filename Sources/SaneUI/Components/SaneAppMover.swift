#if os(macOS)
    import AppKit

    /// Move-to-Applications prompt for all SaneApps.
    ///
    /// Call in `applicationDidFinishLaunching`, guarded by `#if !DEBUG` (and `!APP_STORE`
    /// for App Store builds). Returns `true` if the app is being moved — caller should
    /// return early to avoid double initialization.
    ///
    /// ```swift
    /// #if !DEBUG
    ///     if SaneAppMover.moveToApplicationsFolderIfNeeded() { return }
    /// #endif
    /// ```
    ///
    /// How it works:
    /// 1. Checks if already in /Applications — exits early if so
    /// 2. Shows a native alert asking the user to move
    /// 3. Tries direct FileManager move (works if user has write access)
    /// 4. Falls back to AppleScript with admin privileges (password prompt)
    /// 5. Relaunches from /Applications on success
    public enum SaneAppMover {
        private static var osascriptExecutableURL: URL {
            URL(fileURLWithPath: ["/usr/bin", "osascript"].joined(separator: "/"))
        }

        static func isInApplicationsDirectory(_ appPath: String, homeDirectory: String = NSHomeDirectory()) -> Bool {
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

        @MainActor
        @discardableResult
        public static func moveToApplicationsFolderIfNeeded() -> Bool {
            if ProcessInfo.processInfo.environment["SANEAPPS_SKIP_MOVE_TO_APPLICATIONS"] == "1" ||
                ProcessInfo.processInfo.arguments.contains("--sane-skip-app-move")
            {
                return false
            }

            let appPath = Bundle.main.bundlePath
            let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? "This app"
            let appBundleName = URL(fileURLWithPath: appPath).lastPathComponent

            // Treat both /Applications and ~/Applications as installed locations.
            // This avoids update-time relaunch loops when Sparkle relaunches from ~/Applications.
            guard !isInApplicationsDirectory(appPath) else { return false }

            NSApp.activate()

            let alert = NSAlert()
            alert.messageText = "Move to Applications?"
            alert.informativeText = "\(appName) works best from your Applications folder. Move it there now? You may be asked for your password."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Move to Applications")
            alert.addButton(withTitle: "Not Now")

            guard alert.runModal() == .alertFirstButtonReturn else { return false }

            let destPath = "/Applications/\(appBundleName)"
            let fm = FileManager.default

            // Try direct move first (no admin needed if user owns /Applications)
            var moved = false
            do {
                if fm.fileExists(atPath: destPath) {
                    try fm.removeItem(atPath: destPath)
                }
                try fm.moveItem(atPath: appPath, toPath: destPath)
                moved = true
            } catch {
                // Direct move failed — need admin privileges
            }

            if !moved {
                let escapedAppPath = appPath.replacingOccurrences(of: "'", with: "'\\''")
                let escapedDestPath = destPath.replacingOccurrences(of: "'", with: "'\\''")
                let script = "do shell script \"rm -rf '\(escapedDestPath)' && mv '\(escapedAppPath)' '\(escapedDestPath)'\" with administrator privileges"

                let osa = Process()
                osa.executableURL = osascriptExecutableURL
                osa.arguments = ["-e", script]
                do {
                    try osa.run()
                    osa.waitUntilExit()
                    guard osa.terminationStatus == 0 else {
                        // User cancelled the admin prompt
                        return false
                    }
                } catch {
                    return false
                }
            }

            // Relaunch from /Applications
            var relaunchSucceeded = false
            do {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                // Force a brand-new process. Without -n, LaunchServices can send a reopen
                // event to the current process, then this process terminates and nothing remains running.
                task.arguments = ["-n", destPath]
                try task.run()
                task.waitUntilExit()
                relaunchSucceeded = task.terminationStatus == 0
            } catch {
                relaunchSucceeded = false
            }

            // Keep the current process alive if relaunch fails.
            guard relaunchSucceeded else { return false }
            NSApp.terminate(nil)
            return true
        }
    }
#endif
