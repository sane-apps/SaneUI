import ServiceManagement
import SwiftUI

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

    private var isProperInstall: Bool {
        let path = Bundle.main.bundlePath
        return !path.contains("DerivedData")
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        guard isProperInstall else {
            launchAtLogin = false
            return
        }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Revert toggle on error
            launchAtLogin = !launchAtLogin
        }
    }

    private func checkLaunchAtLogin() {
        let status = SMAppService.mainApp.status
        launchAtLogin = (status == .enabled)
    }
}
