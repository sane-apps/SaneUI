import SwiftUI

public enum SaneSparkleCheckFrequency: String, CaseIterable, Identifiable, Sendable {
    case daily
    case weekly

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .daily: "Daily"
        case .weekly: "Weekly"
        }
    }

    public var interval: TimeInterval {
        switch self {
        case .daily: 60 * 60 * 24
        case .weekly: 60 * 60 * 24 * 7
        }
    }

    public static func resolve(updateCheckInterval: TimeInterval) -> Self {
        let threshold = (Self.daily.interval + Self.weekly.interval) / 2
        return updateCheckInterval >= threshold ? .weekly : .daily
    }

    public static func normalizedInterval(from updateCheckInterval: TimeInterval) -> TimeInterval {
        resolve(updateCheckInterval: updateCheckInterval).interval
    }
}

/// A settings section for Sparkle auto-updates: toggle + frequency + "Check Now" button.
///
/// The caller must provide bindings to the auto-check setting and a check action.
/// Sparkle itself remains in each app (not in SaneUI) because each app has its own
/// `SPUStandardUpdaterController` instance. This component just provides the UI.
///
/// ```swift
/// CompactSection("Software Updates") {
///     SaneSparkleRow(
///         automaticallyChecks: $settings.checkForUpdatesAutomatically,
///         checkFrequency: $checkFrequency,
///         onCheckNow: { updateService.checkForUpdates() }
///     )
/// }
/// ```
public struct SaneSparkleRow: View {
    @Binding private var automaticallyChecks: Bool
    @Binding private var checkFrequency: SaneSparkleCheckFrequency
    private let onCheckNow: () -> Void
    @State private var isChecking = false

    public init(
        automaticallyChecks: Binding<Bool>,
        checkFrequency: Binding<SaneSparkleCheckFrequency>,
        onCheckNow: @escaping () -> Void
    ) {
        _automaticallyChecks = automaticallyChecks
        _checkFrequency = checkFrequency
        self.onCheckNow = onCheckNow
    }

    public var body: some View {
        CompactToggle(
            label: "Check for updates automatically",
            isOn: $automaticallyChecks
        )
        .help("Periodically check for new versions")

        CompactDivider()

        CompactRow("Check frequency") {
            Picker("", selection: $checkFrequency) {
                ForEach(SaneSparkleCheckFrequency.allCases) { frequency in
                    Text(frequency.title).tag(frequency)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
            .disabled(!automaticallyChecks)
        }
        .help("Choose how often automatic update checks run")

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
