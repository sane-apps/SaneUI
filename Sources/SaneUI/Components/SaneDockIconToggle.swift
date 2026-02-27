import AppKit
import SwiftUI

/// A toggle row for "Show app in Dock" that manages NSApplication activation policy.
///
/// When the dock icon is hidden, the app runs as a menu bar accessory.
/// When shown, the app appears in Dock and Cmd+Tab.
///
/// ```swift
/// CompactSection("App Visibility") {
///     SaneDockIconToggle(showDockIcon: $settings.showDockIcon)
/// }
/// ```
public struct SaneDockIconToggle: View {
    @Binding private var showDockIcon: Bool

    public init(showDockIcon: Binding<Bool>) {
        _showDockIcon = showDockIcon
    }

    public var body: some View {
        CompactToggle(
            label: "Show app in Dock",
            isOn: Binding(
                get: { showDockIcon },
                set: { newValue in
                    showDockIcon = newValue
                    SaneActivationPolicy.applyPolicy(showDockIcon: newValue)
                }
            )
        )
        .help("Show this app's icon in the Dock and Cmd+Tab switcher")
    }
}

// MARK: - SaneActivationPolicy

/// Manages NSApplication activation policy (dock icon visibility).
///
/// Call `applyInitialPolicy(showDockIcon:)` in `applicationDidFinishLaunching`.
/// Call `applyPolicy(showDockIcon:)` when the user toggles the setting.
public enum SaneActivationPolicy {
    /// Apply policy on app launch with retries to handle timing issues.
    @MainActor
    public static func applyInitialPolicy(showDockIcon: Bool) {
        guard !isHeadlessEnvironment() else { return }
        Task { @MainActor in
            enforcePolicy(showDockIcon: showDockIcon, retries: 10)
        }
    }

    /// Apply policy immediately (e.g. from settings toggle).
    @MainActor
    public static func applyPolicy(showDockIcon: Bool) {
        guard !isHeadlessEnvironment() else { return }
        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory
        NSApp.setActivationPolicy(policy)

        if showDockIcon {
            NSApp.activate()
        }
    }

    /// Re-enforce the policy (e.g. after closing settings window).
    @MainActor
    public static func restorePolicy(showDockIcon: Bool) {
        guard !isHeadlessEnvironment() else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            enforcePolicy(showDockIcon: showDockIcon, retries: 4)
        }
    }

    @MainActor
    private static func enforcePolicy(showDockIcon: Bool, retries: Int) {
        guard let app = NSApp else {
            guard retries > 0 else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(100))
                enforcePolicy(showDockIcon: showDockIcon, retries: retries - 1)
            }
            return
        }

        let policy: NSApplication.ActivationPolicy = showDockIcon ? .regular : .accessory

        if app.activationPolicy() != policy {
            app.setActivationPolicy(policy)
        }

        guard retries > 0 else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard let app = NSApp else { return }
            if app.activationPolicy() != policy {
                app.setActivationPolicy(policy)
            }
            enforcePolicy(showDockIcon: showDockIcon, retries: retries - 1)
        }
    }

    private static func isHeadlessEnvironment() -> Bool {
        let env = ProcessInfo.processInfo.environment
        if env["CI"] != nil || env["GITHUB_ACTIONS"] != nil { return true }
        if let bundleID = Bundle.main.bundleIdentifier,
           bundleID.hasSuffix("Tests") || bundleID.contains("xctest") { return true }
        if NSClassFromString("XCTestCase") != nil { return true }
        return false
    }
}
