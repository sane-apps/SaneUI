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
