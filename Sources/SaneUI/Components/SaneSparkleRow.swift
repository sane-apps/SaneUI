import SwiftUI

/// A settings section for Sparkle auto-updates: toggle + "Check Now" button.
///
/// The caller must provide bindings to the auto-check setting and a check action.
/// Sparkle itself remains in each app (not in SaneUI) because each app has its own
/// `SPUStandardUpdaterController` instance. This component just provides the UI.
///
/// ```swift
/// CompactSection("Software Updates") {
///     SaneSparkleRow(
///         automaticallyChecks: $settings.checkForUpdatesAutomatically,
///         onCheckNow: { updateService.checkForUpdates() }
///     )
/// }
/// ```
public struct SaneSparkleRow: View {
    @Binding private var automaticallyChecks: Bool
    private let onCheckNow: () -> Void
    @State private var isChecking = false

    public init(
        automaticallyChecks: Binding<Bool>,
        onCheckNow: @escaping () -> Void
    ) {
        _automaticallyChecks = automaticallyChecks
        self.onCheckNow = onCheckNow
    }

    public var body: some View {
        CompactToggle(
            label: "Check for updates automatically",
            isOn: $automaticallyChecks
        )
        .help("Periodically check for new versions")

        CompactDivider()

        CompactRow("Actions") {
            Button(isChecking ? "Checking\u{2026}" : "Check Now") {
                guard !isChecking else { return }
                isChecking = true
                onCheckNow()

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(5))
                    isChecking = false
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isChecking)
            .help("Check for updates right now")
        }
    }
}
