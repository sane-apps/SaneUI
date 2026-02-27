import AppKit
import Foundation
import OSLog

// MARK: - SaneDiagnosticReport

/// Diagnostic information for issue reporting, shared across all SaneApps.
/// Each app provides its own settings summary via the `settingsCollector` closure.
public struct SaneDiagnosticReport: Sendable {
    public let appName: String
    public let appVersion: String
    public let buildNumber: String
    public let macOSVersion: String
    public let hardwareModel: String
    public let recentLogs: [LogEntry]
    public let settingsSummary: String
    public let collectedAt: Date

    public struct LogEntry: Sendable {
        public let timestamp: Date
        public let level: String
        public let message: String

        public init(timestamp: Date, level: String, message: String) {
            self.timestamp = timestamp
            self.level = level
            self.message = message
        }
    }

    public init(
        appName: String,
        appVersion: String,
        buildNumber: String,
        macOSVersion: String,
        hardwareModel: String,
        recentLogs: [LogEntry],
        settingsSummary: String,
        collectedAt: Date
    ) {
        self.appName = appName
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.macOSVersion = macOSVersion
        self.hardwareModel = hardwareModel
        self.recentLogs = recentLogs
        self.settingsSummary = settingsSummary
        self.collectedAt = collectedAt
    }

    /// Generate markdown-formatted report for GitHub issue
    public func toMarkdown(userDescription: String) -> String {
        var md = """
        ## Issue Description
        \(userDescription)

        ---

        ## Environment
        | Property | Value |
        |----------|-------|
        | App Version | \(appVersion) (\(buildNumber)) |
        | macOS | \(macOSVersion) |
        | Hardware | \(hardwareModel) |
        | Collected | \(ISO8601DateFormatter().string(from: collectedAt)) |

        """

        if !recentLogs.isEmpty {
            md += """

            ## Recent Logs (last 5 minutes)
            ```
            \(formattedLogs)
            ```

            """
        }

        md += """

        ## Settings Summary
        ```
        \(settingsSummary)
        ```

        ---
        *Submitted via \(appName)'s in-app feedback*
        """

        return md
    }

    private var formattedLogs: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"

        return recentLogs.prefix(50).map { entry in
            "[\(formatter.string(from: entry.timestamp))] [\(entry.level)] \(entry.message)"
        }.joined(separator: "\n")
    }
}

// MARK: - GitHub Issue URL Generation

public extension SaneDiagnosticReport {
    /// Generate a URL that opens a pre-filled GitHub issue.
    /// Diagnostics are copied to clipboard instead of stuffed into URL params
    /// (GitHub has URL length limits and the full markdown easily exceeds them).
    func gitHubIssueURL(title: String, userDescription: String, githubRepo: String) -> URL? {
        let fullBody = toMarkdown(userDescription: userDescription)

        // Copy full diagnostics to clipboard — user pastes into the issue
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(fullBody, forType: .string)

        // URL only carries the title + short user text (hard-clamped).
        let trimmedDescription = userDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseDescription = trimmedDescription.isEmpty ? "<describe what happened>" : trimmedDescription
        let maxDescriptionChars = 600
        let shortDescription: String = if baseDescription.count > maxDescriptionChars {
            String(baseDescription.prefix(maxDescriptionChars)) + "\n\n[Description truncated — full diagnostics copied to clipboard.]"
        } else {
            baseDescription
        }

        let shortBody = """
        ## Issue Description
        \(shortDescription)

        ---
        **Diagnostics have been copied to your clipboard.** Paste them below:


        """

        var components = URLComponents(string: "https://github.com/sane-apps/\(githubRepo)/issues/new")
        components?.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "body", value: shortBody)
        ]

        return components?.url
    }
}

// MARK: - SaneDiagnosticsService

/// Shared diagnostics collector for all SaneApps.
///
/// Each app creates an instance with its own subsystem and settings collector:
/// ```swift
/// let diagnostics = SaneDiagnosticsService(
///     appName: "SaneBar",
///     subsystem: "com.sanebar.app",
///     githubRepo: "SaneBar",
///     settingsCollector: { await collectMySettings() }
/// )
/// ```
public final class SaneDiagnosticsService: @unchecked Sendable {
    private let appName: String
    private let subsystem: String
    public let githubRepo: String
    private let settingsCollector: @Sendable () async -> String

    public init(
        appName: String,
        subsystem: String,
        githubRepo: String,
        settingsCollector: @escaping @Sendable () async -> String
    ) {
        self.appName = appName
        self.subsystem = subsystem
        self.githubRepo = githubRepo
        self.settingsCollector = settingsCollector
    }

    /// Convenience initializer for apps with no custom settings to report
    public convenience init(appName: String, subsystem: String, githubRepo: String) {
        self.init(appName: appName, subsystem: subsystem, githubRepo: githubRepo) {
            "No app-specific settings collected."
        }
    }

    public func collectDiagnostics() async -> SaneDiagnosticReport {
        async let logs = collectRecentLogs()
        async let settings = settingsCollector()

        return await SaneDiagnosticReport(
            appName: appName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            macOSVersion: macOSVersion,
            hardwareModel: hardwareModel,
            recentLogs: logs,
            settingsSummary: settings,
            collectedAt: Date()
        )
    }

    // MARK: - App Info

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    // MARK: - System Info

    private var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private var hardwareModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let modelString = String(
            bytes: model.prefix(while: { $0 != 0 }).map(UInt8.init),
            encoding: .utf8
        ) ?? "Unknown"

        #if arch(arm64)
            return "\(modelString) (Apple Silicon)"
        #else
            return "\(modelString) (Intel)"
        #endif
    }

    // MARK: - Log Collection

    private func collectRecentLogs() async -> [SaneDiagnosticReport.LogEntry] {
        guard #available(macOS 15.0, *) else {
            return [
                SaneDiagnosticReport.LogEntry(
                    timestamp: Date(),
                    level: "INFO",
                    message: "Log collection requires macOS 15+. Current OS: \(macOSVersion). Paste logs manually: log show --predicate 'subsystem == \"\(subsystem)\"' --last 5m --style compact"
                )
            ]
        }

        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let fiveMinutesAgo = Date().addingTimeInterval(-5 * 60)
            let position = store.position(date: fiveMinutesAgo)

            let predicate = NSPredicate(format: "subsystem == %@", subsystem)
            let entries = try store.getEntries(at: position, matching: predicate)

            return entries.compactMap { entry -> SaneDiagnosticReport.LogEntry? in
                guard let logEntry = entry as? OSLogEntryLog else { return nil }

                let level = switch logEntry.level {
                case .debug: "DEBUG"
                case .info: "INFO"
                case .notice: "NOTICE"
                case .error: "ERROR"
                case .fault: "FAULT"
                default: "LOG"
                }

                return SaneDiagnosticReport.LogEntry(
                    timestamp: logEntry.date,
                    level: level,
                    message: sanitize(logEntry.composedMessage)
                )
            }
        } catch {
            return [
                SaneDiagnosticReport.LogEntry(
                    timestamp: Date(),
                    level: "ERROR",
                    message: "Failed to collect logs: \(error.localizedDescription)"
                ),
                SaneDiagnosticReport.LogEntry(
                    timestamp: Date(),
                    level: "INFO",
                    message: "Tip: paste logs manually by running in Terminal: log show --predicate 'subsystem == \"\(subsystem)\"' --last 5m --style compact"
                )
            ]
        }
    }

    // MARK: - Privacy

    private func sanitize(_ message: String) -> String {
        var sanitized = message

        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        sanitized = sanitized.replacingOccurrences(of: homeDir, with: "~")

        let patterns = [
            "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}",
            "\\b[A-Za-z0-9]{32,}\\b"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                sanitized = regex.stringByReplacingMatches(
                    in: sanitized,
                    range: NSRange(sanitized.startIndex..., in: sanitized),
                    withTemplate: "[REDACTED]"
                )
            }
        }

        return sanitized
    }
}
