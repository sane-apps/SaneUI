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

        public init(
            automaticCheckLabel: String,
            automaticCheckHelp: String,
            checkFrequencyLabel: String,
            checkFrequencyHelp: String,
            actionsLabel: String,
            checkingLabel: String,
            checkNowLabel: String,
            checkNowHelp: String
        ) {
            self.automaticCheckLabel = automaticCheckLabel
            self.automaticCheckHelp = automaticCheckHelp
            self.checkFrequencyLabel = checkFrequencyLabel
            self.checkFrequencyHelp = checkFrequencyHelp
            self.actionsLabel = actionsLabel
            self.checkingLabel = checkingLabel
            self.checkNowLabel = checkNowLabel
            self.checkNowHelp = checkNowHelp
        }

        public static let `default` = Labels(
            automaticCheckLabel: "Check for updates automatically",
            automaticCheckHelp: "Periodically check for new versions",
            checkFrequencyLabel: "Check frequency",
            checkFrequencyHelp: "Choose how often automatic update checks run",
            actionsLabel: "Actions",
            checkingLabel: "Checking...",
            checkNowLabel: "Check Now",
            checkNowHelp: "Check for updates right now"
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
                    Text(frequency.title).tag(frequency)
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
