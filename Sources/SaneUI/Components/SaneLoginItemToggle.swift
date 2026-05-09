#if os(macOS)
import AppKit
import ServiceManagement
import SwiftUI

public enum SaneBackgroundAppDefaults {
    public static let showDockIcon = false
    public static let launchAtLogin = true
    public static let launchAtLoginDefaultPromptKey = "hasAnsweredLaunchAtLoginDefaultPrompt"
    public static let autoEnableLaunchAtLoginKey = launchAtLoginDefaultPromptKey
}

public enum SaneLoginItemDefaultPromptResult: Equatable {
    case defaultDisabled
    case ineligibleInstall
    case alreadyPrompted
    case alreadyEnabled
    case enabled
    case declined
    case failed
}

public enum SaneLoginItemPolicy {
    public static func isEligibleInstall(
        bundlePath: String = Bundle.main.bundlePath,
        homeDirectory: String = NSHomeDirectory()
    ) -> Bool {
        guard !bundlePath.contains("DerivedData") else { return false }
        return SaneInstallLocation.isInApplicationsDirectory(bundlePath, homeDirectory: homeDirectory)
    }

    public static func toggleValue(
        statusProvider: () -> SMAppService.Status = { SMAppService.mainApp.status }
    ) -> Bool {
        switch statusProvider() {
        case .enabled, .requiresApproval:
            true
        default:
            false
        }
    }

    @discardableResult
    public static func setEnabled(
        _ enabled: Bool,
        markerKey: String = SaneBackgroundAppDefaults.autoEnableLaunchAtLoginKey,
        bundlePath: String = Bundle.main.bundlePath,
        homeDirectory: String = NSHomeDirectory(),
        userDefaults: UserDefaults = .standard,
        register: () throws -> Void = { try SMAppService.mainApp.register() },
        unregister: () throws -> Void = { try SMAppService.mainApp.unregister() }
    ) throws -> Bool {
        guard isEligibleInstall(bundlePath: bundlePath, homeDirectory: homeDirectory) else {
            return false
        }

        if enabled {
            try register()
        } else {
            try unregister()
        }

        userDefaults.set(true, forKey: markerKey)
        return true
    }

    public static func shouldOfferDefaultPrompt(
        markerKey: String = SaneBackgroundAppDefaults.launchAtLoginDefaultPromptKey,
        defaultEnabled: Bool = SaneBackgroundAppDefaults.launchAtLogin,
        bundlePath: String = Bundle.main.bundlePath,
        homeDirectory: String = NSHomeDirectory(),
        userDefaults: UserDefaults = .standard,
        statusProvider: () -> SMAppService.Status = { SMAppService.mainApp.status }
    ) -> Bool {
        guard defaultEnabled else { return false }
        guard isEligibleInstall(bundlePath: bundlePath, homeDirectory: homeDirectory) else { return false }
        guard !userDefaults.bool(forKey: markerKey) else { return false }
        return !toggleValue(statusProvider: statusProvider)
    }

    public static func scheduleDefaultLaunchAtLoginPrompt(
        appName: String,
        delay: TimeInterval = 1.0
    ) {
        guard SaneBackgroundAppDefaults.launchAtLogin else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            Task { @MainActor in
                _ = offerDefaultLaunchAtLoginIfNeeded(appName: appName)
            }
        }
    }

    @MainActor
    @discardableResult
    public static func offerDefaultLaunchAtLoginIfNeeded(
        appName: String,
        markerKey: String = SaneBackgroundAppDefaults.launchAtLoginDefaultPromptKey,
        defaultEnabled: Bool = SaneBackgroundAppDefaults.launchAtLogin,
        bundlePath: String = Bundle.main.bundlePath,
        homeDirectory: String = NSHomeDirectory(),
        userDefaults: UserDefaults = .standard,
        statusProvider: () -> SMAppService.Status = { SMAppService.mainApp.status },
        prompt: (String) -> Bool = { appName in
            let alert = NSAlert()
            alert.messageText = "Start \(appName) at login?"
            alert.informativeText = "\(appName) works best when it starts with your Mac. You can turn this off anytime in Settings."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Start at Login")
            alert.addButton(withTitle: "Not Now")
            return alert.runModal() == .alertFirstButtonReturn
        },
        register: () throws -> Void = { try SMAppService.mainApp.register() },
        failurePresenter: (String) -> Void = { message in
            let alert = NSAlert()
            alert.messageText = "Start at Login could not be updated"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    ) -> SaneLoginItemDefaultPromptResult {
        guard defaultEnabled else { return .defaultDisabled }
        guard isEligibleInstall(bundlePath: bundlePath, homeDirectory: homeDirectory) else {
            return .ineligibleInstall
        }
        guard !userDefaults.bool(forKey: markerKey) else { return .alreadyPrompted }

        if toggleValue(statusProvider: statusProvider) {
            userDefaults.set(true, forKey: markerKey)
            return .alreadyEnabled
        }

        guard prompt(appName) else {
            userDefaults.set(true, forKey: markerKey)
            return .declined
        }

        userDefaults.set(true, forKey: markerKey)
        do {
            try register()
            return .enabled
        } catch {
            failurePresenter("Open System Settings → General → Login Items and enable \(appName), or try again from \(appName) Settings.")
            return .failed
        }
    }
}

/// A toggle row for "Start automatically at login" using SMAppService.
///
/// Guards against DerivedData debug builds and reverts the toggle on error.
///
/// ```swift
/// CompactSection("Startup") {
///     SaneLoginItemToggle()
/// }
/// ```
public struct SaneLoginItemToggle: View {
    @State private var launchAtLogin = false
    @State private var statusMessage: String?

    public init() {}

    public var body: some View {
        Group {
            CompactToggle(
                label: "Start automatically at login",
                isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        launchAtLogin = newValue
                        setLaunchAtLogin(newValue)
                    }
                )
            )
            .help("Launch this app when you log in to your Mac")

            if let statusMessage {
                SaneInlineHelp(statusMessage)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 4)
            }
        }
        .onAppear { checkLaunchAtLogin() }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            let didApply = try SaneLoginItemPolicy.setEnabled(enabled)
            if !didApply {
                launchAtLogin = SaneLoginItemPolicy.toggleValue()
                statusMessage = "Start at login is available after the app is opened from your Applications folder."
            } else {
                statusMessage = nil
            }
        } catch {
            // Revert toggle on error
            launchAtLogin = SaneLoginItemPolicy.toggleValue()
            statusMessage = "macOS could not update Start at Login. Open System Settings → General → Login Items and try again."
        }
    }

    private func checkLaunchAtLogin() {
        launchAtLogin = SaneLoginItemPolicy.toggleValue()
        statusMessage = SaneLoginItemPolicy.isEligibleInstall() ? nil : "Start at login is available after the app is opened from your Applications folder."
    }
}
#endif
