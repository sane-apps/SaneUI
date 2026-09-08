import SwiftUI

/// Factual list of what shipped after a direct-download trial.
/// Apps pass their own bullets. Empty lists render nothing.
public struct ExpiredTrialSinceUpdateList: View {
    public let updates: [String]

    public init(updates: [String]) {
        self.updates = updates
    }

    public var body: some View {
        if !updates.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Since your trial")
                    .font(.system(size: SaneTypography.bodySize, weight: .semibold))
                    .foregroundStyle(.white)

                ForEach(updates, id: \.self) { update in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                            .font(.system(size: SaneTypography.bodySize, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(update)
                            .font(.system(size: SaneTypography.bodySize, weight: .medium))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Since your trial. \(updates.joined(separator: ". "))")
        }
    }
}
