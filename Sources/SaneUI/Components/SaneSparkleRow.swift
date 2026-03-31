import SwiftUI

public enum SaneSparkleCheckFrequency: String, CaseIterable, Identifiable, Sendable {
    case daily
    case weekly

    public var id: String { rawValue }

    public var title: String {
        title(labels: .default)
    }

    public func title(labels: SaneSparkleRow.Labels) -> String {
        switch self {
        case .daily: labels.dailyTitle
        case .weekly: labels.weeklyTitle
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

public struct SaneSparkleRow: View {
    public struct Labels: Sendable {
        public let automaticCheckLabel: String
        public let automaticCheckHelp: String
        public let checkFrequencyLabel: String
        public let checkFrequencyHelp: String
        public let actionsLabel: String
        public let checkingLabel: String
        public let checkNowLabel: String
        public let checkNowHelp: String
        public let dailyTitle: String
        public let weeklyTitle: String

        public init(
            automaticCheckLabel: String,
            automaticCheckHelp: String,
            checkFrequencyLabel: String,
            checkFrequencyHelp: String,
            actionsLabel: String,
            checkingLabel: String,
            checkNowLabel: String,
            checkNowHelp: String,
            dailyTitle: String,
            weeklyTitle: String
        ) {
            self.automaticCheckLabel = automaticCheckLabel
            self.automaticCheckHelp = automaticCheckHelp
            self.checkFrequencyLabel = checkFrequencyLabel
            self.checkFrequencyHelp = checkFrequencyHelp
            self.actionsLabel = actionsLabel
            self.checkingLabel = checkingLabel
            self.checkNowLabel = checkNowLabel
            self.checkNowHelp = checkNowHelp
            self.dailyTitle = dailyTitle
            self.weeklyTitle = weeklyTitle
        }

        public static let `default` = Labels(
            automaticCheckLabel: String(localized: "saneui.sparkle.automatic_check_label", defaultValue: "Check for updates automatically", bundle: .module),
            automaticCheckHelp: String(localized: "saneui.sparkle.automatic_check_help", defaultValue: "Periodically check for new versions", bundle: .module),
            checkFrequencyLabel: String(localized: "saneui.sparkle.check_frequency_label", defaultValue: "Check frequency", bundle: .module),
            checkFrequencyHelp: String(localized: "saneui.sparkle.check_frequency_help", defaultValue: "Choose how often automatic update checks run", bundle: .module),
            actionsLabel: String(localized: "saneui.sparkle.actions_label", defaultValue: "Actions", bundle: .module),
            checkingLabel: String(localized: "saneui.sparkle.checking_label", defaultValue: "Checking...", bundle: .module),
            checkNowLabel: String(localized: "saneui.sparkle.check_now_label", defaultValue: "Check Now", bundle: .module),
            checkNowHelp: String(localized: "saneui.sparkle.check_now_help", defaultValue: "Check for updates right now", bundle: .module),
            dailyTitle: String(localized: "saneui.sparkle.daily_title", defaultValue: "Daily", bundle: .module),
            weeklyTitle: String(localized: "saneui.sparkle.weekly_title", defaultValue: "Weekly", bundle: .module)
        )
    }

    @Binding private var automaticallyChecks: Bool
    @Binding private var checkFrequency: SaneSparkleCheckFrequency
    private let labels: Labels
    private let onCheckNow: () -> Void
    @State private var isChecking = false

    public init(
        automaticallyChecks: Binding<Bool>,
        checkFrequency: Binding<SaneSparkleCheckFrequency>,
        onCheckNow: @escaping () -> Void
    ) {
        self.init(
            automaticallyChecks: automaticallyChecks,
            checkFrequency: checkFrequency,
            labels: .default,
            onCheckNow: onCheckNow
        )
    }

    public init(
        automaticallyChecks: Binding<Bool>,
        checkFrequency: Binding<SaneSparkleCheckFrequency>,
        labels: Labels,
        onCheckNow: @escaping () -> Void
    ) {
        _automaticallyChecks = automaticallyChecks
        _checkFrequency = checkFrequency
        self.labels = labels
        self.onCheckNow = onCheckNow
    }

    public var body: some View {
        CompactToggle(label: labels.automaticCheckLabel, isOn: $automaticallyChecks)
            .help(labels.automaticCheckHelp)

        CompactDivider()

        CompactRow(labels.checkFrequencyLabel) {
            Picker("", selection: $checkFrequency) {
                ForEach(SaneSparkleCheckFrequency.allCases) { frequency in
                    Text(frequency.title(labels: labels)).tag(frequency)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
            .disabled(!automaticallyChecks)
        }
        .help(labels.checkFrequencyHelp)

        CompactDivider()

        CompactRow(labels.actionsLabel) {
            Button(isChecking ? labels.checkingLabel : labels.checkNowLabel) {
                guard !isChecking else { return }
                isChecking = true
                onCheckNow()

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(5))
                    isChecking = false
                }
            }
            .buttonStyle(SaneActionButtonStyle())
            .disabled(isChecking)
            .help(labels.checkNowHelp)
        }
    }
}
