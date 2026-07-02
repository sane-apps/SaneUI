import SaneUI
import SwiftUI

public enum SaneSparkleCheckFrequency: String, CaseIterable, Identifiable, Sendable {
    case daily
    case weekly

    public var id: String {
        rawValue
    }

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

        /// Demo/catalog target only — plain literals, no localization catalog
        /// ownership here (the real .xcstrings entries live in the SaneUI
        /// target; shipping apps supply their own Labels via app-local copies
        /// of this component, e.g. SaneClip's UI/Settings/SaneSparkleRow.swift).
        public static let `default` = Labels(
            automaticCheckLabel: "Check for updates automatically",
            automaticCheckHelp: "Periodically check for new versions",
            checkFrequencyLabel: "Check frequency",
            checkFrequencyHelp: "Choose how often automatic update checks run",
            actionsLabel: "Actions",
            checkingLabel: "Checking...",
            checkNowLabel: "Check Now",
            checkNowHelp: "Check for updates right now",
            dailyTitle: "Daily",
            weeklyTitle: "Weekly"
        )
    }

    @Binding private var automaticallyChecks: Bool
    @Binding private var checkFrequency: SaneSparkleCheckFrequency
    private let isAvailable: Bool
    private let unavailableStatus: String?
    private let recoveryActionLabel: String?
    private let recoveryActionHelp: String?
    private let labels: Labels
    private let onCheckNow: () -> Void
    private let onRecoveryAction: (() -> Void)?
    @State private var isChecking = false

    public init(
        automaticallyChecks: Binding<Bool>,
        checkFrequency: Binding<SaneSparkleCheckFrequency>,
        isAvailable: Bool = true,
        unavailableStatus: String? = nil,
        recoveryActionLabel: String? = nil,
        recoveryActionHelp: String? = nil,
        onRecoveryAction: (() -> Void)? = nil,
        onCheckNow: @escaping () -> Void
    ) {
        self.init(
            automaticallyChecks: automaticallyChecks,
            checkFrequency: checkFrequency,
            isAvailable: isAvailable,
            unavailableStatus: unavailableStatus,
            recoveryActionLabel: recoveryActionLabel,
            recoveryActionHelp: recoveryActionHelp,
            onRecoveryAction: onRecoveryAction,
            labels: .default,
            onCheckNow: onCheckNow
        )
    }

    public init(
        automaticallyChecks: Binding<Bool>,
        checkFrequency: Binding<SaneSparkleCheckFrequency>,
        isAvailable: Bool = true,
        unavailableStatus: String? = nil,
        recoveryActionLabel: String? = nil,
        recoveryActionHelp: String? = nil,
        onRecoveryAction: (() -> Void)? = nil,
        labels: Labels,
        onCheckNow: @escaping () -> Void
    ) {
        _automaticallyChecks = automaticallyChecks
        _checkFrequency = checkFrequency
        self.isAvailable = isAvailable
        self.unavailableStatus = unavailableStatus
        self.recoveryActionLabel = recoveryActionLabel
        self.recoveryActionHelp = recoveryActionHelp
        self.labels = labels
        self.onCheckNow = onCheckNow
        self.onRecoveryAction = onRecoveryAction
    }

    public var body: some View {
        if let unavailableStatus, !isAvailable {
            CompactRow("Status") {
                Text(unavailableStatus)
                    .font(.system(size: 13, weight: .medium))
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            CompactDivider()

            if let recoveryActionLabel, let onRecoveryAction {
                CompactRow(labels.actionsLabel) {
                    Button(recoveryActionLabel) {
                        onRecoveryAction()
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .help(recoveryActionHelp ?? recoveryActionLabel)
                }

                CompactDivider()
            }
        }

        CompactToggle(label: labels.automaticCheckLabel, isOn: $automaticallyChecks)
            .help(labels.automaticCheckHelp)
            .disabled(!isAvailable)

        CompactDivider()

        CompactRow(labels.checkFrequencyLabel) {
            Picker("", selection: $checkFrequency) {
                ForEach(SaneSparkleCheckFrequency.allCases) { frequency in
                    Text(frequency.title(labels: labels)).tag(frequency)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
            .disabled(!isAvailable || !automaticallyChecks)
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
            .disabled(isChecking || !isAvailable)
            .help(isAvailable ? labels.checkNowHelp : (unavailableStatus ?? labels.checkNowHelp))
        }
    }
}
