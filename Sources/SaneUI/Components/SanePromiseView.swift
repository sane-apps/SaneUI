import SwiftUI

/// The Sane Promise page — shared philosophy section used in onboarding across all SaneApps.
///
/// Displays the 2 Timothy 1:7 scripture with three pillar cards (Power, Love, Sound Mind).
/// Each app can customize the tagline (e.g. "Why SaneBar?") and pillar descriptions.
///
/// ```swift
/// // Default descriptions:
/// SanePromiseView(appName: "SaneBar")
///
/// // Custom pillar descriptions:
/// SanePromiseView(
///     appName: "SaneClip",
///     powerLines: ["Your clipboard never leaves your Mac.", "End-to-end encrypted.", "Open source."],
///     loveLines: ["Built to serve you.", "Pay once, yours forever.", "No subscriptions."],
///     soundMindLines: ["No clutter.", "Clean and focused.", "Does one thing well."]
/// )
/// ```
public struct SanePromiseView: View {
    private let appName: String
    private let powerLines: [String]
    private let loveLines: [String]
    private let soundMindLines: [String]

    public init(
        appName: String,
        powerLines: [String] = [
            "Your data stays on your device.",
            "100% transparent code.",
            "Actively maintained."
        ],
        loveLines: [String] = [
            "Built to serve you.",
            "Pay once, yours forever.",
            "No subscriptions."
        ],
        soundMindLines: [String] = [
            "Calm and focused.",
            "Does one thing well.",
            "No clutter."
        ]
    ) {
        self.appName = appName
        self.powerLines = powerLines
        self.loveLines = loveLines
        self.soundMindLines = soundMindLines
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Title
            (Text("Why ").foregroundColor(.teal) +
                Text(appName).foregroundColor(.white) +
                Text("?").foregroundColor(.white))
                .font(.system(size: 28, weight: .bold, design: .serif))

            // Scripture
            VStack(spacing: 6) {
                Text("\"For God has not given us a spirit of fear,")
                    .font(.system(size: 15, design: .serif))
                    .foregroundStyle(.white)
                (Text("but of ").foregroundColor(.white) +
                    Text("power").foregroundColor(.yellow) +
                    Text(" and of ").foregroundColor(.white) +
                    Text("love").foregroundColor(.red) +
                    Text(" and of a ").foregroundColor(.white) +
                    Text("sound mind").foregroundColor(.cyan) +
                    Text(".\"").foregroundColor(.white))
                    .font(.system(size: 15, design: .serif))
                Text("\u{2014} 2 Timothy 1:7")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
            }

            // Three pillars
            HStack(spacing: 14) {
                SanePillarCard(
                    icon: "bolt.fill", color: .yellow, title: "Power",
                    lines: powerLines
                )
                SanePillarCard(
                    icon: "heart.fill", color: .red, title: "Love",
                    lines: loveLines
                )
                SanePillarCard(
                    icon: "brain.head.profile", color: .cyan, title: "Sound Mind",
                    lines: soundMindLines
                )
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Pillar Card

/// A single pillar card in the Sane Promise view.
/// Can be used standalone if an app needs individual pillar cards elsewhere.
public struct SanePillarCard: View {
    private let icon: String
    private let color: Color
    private let title: String
    private let lines: [String]

    private let cardBg = Color(red: 0.08, green: 0.10, blue: 0.18)

    public init(icon: String, color: Color, title: String, lines: [String]) {
        self.icon = icon
        self.color = color
        self.title = title
        self.lines = lines
    }

    public var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 4) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 5) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.green)
                            .frame(width: 12)
                            .padding(.top, 2)
                        Text(line)
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.teal.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.teal.opacity(0.1), radius: 8, x: 0, y: 3)
        )
    }
}
