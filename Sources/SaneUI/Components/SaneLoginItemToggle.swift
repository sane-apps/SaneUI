#if os(macOS)
import ServiceManagement
import SwiftUI

public enum SaneBackgroundAppDefaults {
    public static let showDockIcon = false
    public static let launchAtLogin = true
    public static let autoEnableLaunchAtLoginKey = "hasAutoEnabledLaunchAtLoginDefault"
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
        bundlePath: String = Bundle.main.bundlePath,
        homeDirectory: String = NSHomeDirectory(),
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

        return true
    }

    @discardableResult
    public static func enableByDefaultIfNeeded(
        isFirstLaunch: Bool,
        markerKey: String = SaneBackgroundAppDefaults.autoEnableLaunchAtLoginKey,
        bundlePath: String = Bundle.main.bundlePath,
        homeDirectory: String = NSHomeDirectory(),
        userDefaults: UserDefaults = .standard,
        statusProvider: () -> SMAppService.Status = { SMAppService.mainApp.status },
        register: () throws -> Void = { try SMAppService.mainApp.register() }
    ) -> Bool {
        guard isFirstLaunch else { return false }
        guard !userDefaults.bool(forKey: markerKey) else { return false }
        guard isEligibleInstall(bundlePath: bundlePath, homeDirectory: homeDirectory) else {
            return false
        }

        switch statusProvider() {
        case .enabled, .requiresApproval:
            userDefaults.set(true, forKey: markerKey)
            return true
        case .notRegistered:
            do {
                try register()
                userDefaults.set(true, forKey: markerKey)
                return true
            } catch {
                return false
            }
        case .notFound:
            return false
        @unknown default:
            return false
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

    public init() {}

    public var body: some View {
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
        .onAppear { checkLaunchAtLogin() }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            let didApply = try SaneLoginItemPolicy.setEnabled(enabled)
            if !didApply {
                launchAtLogin = SaneLoginItemPolicy.toggleValue()
            }
        } catch {
            // Revert toggle on error
            launchAtLogin = SaneLoginItemPolicy.toggleValue()
        }
    }

    private func checkLaunchAtLogin() {
        launchAtLogin = SaneLoginItemPolicy.toggleValue()
    }
}
#endif
