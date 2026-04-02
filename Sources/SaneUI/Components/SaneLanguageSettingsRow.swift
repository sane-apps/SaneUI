import SwiftUI

public struct SaneLanguageSettingsRow: View {
    public struct Labels: Sendable {
        public let sectionTitle: String
        public let currentLanguageLabel: String
        public let changeButtonTitle: String
        public let helperText: String
        public let singleLanguageHelperText: String

        public init(
            sectionTitle: String,
            currentLanguageLabel: String,
            changeButtonTitle: String,
            helperText: String,
            singleLanguageHelperText: String
        ) {
            self.sectionTitle = sectionTitle
            self.currentLanguageLabel = currentLanguageLabel
            self.changeButtonTitle = changeButtonTitle
            self.helperText = helperText
            self.singleLanguageHelperText = singleLanguageHelperText
        }

        public static let `default` = Labels(
            sectionTitle: String(localized: "saneui.language.section_title", defaultValue: "Language", bundle: .module),
            currentLanguageLabel: String(localized: "saneui.language.current_language_label", defaultValue: "App Language", bundle: .module),
            changeButtonTitle: String(localized: "saneui.language.change_button_title", defaultValue: "Change", bundle: .module),
            helperText: String(localized: "saneui.language.helper_text", defaultValue: "Change the app language in System Settings. Restart the app if macOS has not refreshed the UI yet.", bundle: .module),
            singleLanguageHelperText: String(localized: "saneui.language.single_language_helper_text", defaultValue: "Add more app localizations to enable per-app language switching in System Settings.", bundle: .module)
        )
    }

    private let bundle: Bundle
    private let labels: Labels
    private let openLanguageSettings: (() -> Void)?

    public init(
        bundle: Bundle = .main,
        labels: Labels = .default,
        openLanguageSettings: (() -> Void)? = nil
    ) {
        self.bundle = bundle
        self.labels = labels
        self.openLanguageSettings = openLanguageSettings
    }

    public var body: some View {
        CompactSection(labels.sectionTitle, icon: "globe", iconColor: SaneSettingsIconSemantic.content.color) {
            CompactRow(labels.currentLanguageLabel, icon: "character.book.closed", iconColor: .white) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        valueText(currentLanguageDisplayName)
                        if canChangeLanguage {
                            changeButton
                        }
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        valueText(currentLanguageDisplayName)
                        if canChangeLanguage {
                            changeButton
                        }
                    }
                }
            }

            CompactDivider()

            Text(canChangeLanguage ? labels.helperText : labels.singleLanguageHelperText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
    }

    private var canChangeLanguage: Bool {
        SaneAppLanguageSupport.canChangeAppLanguage(bundle: bundle)
    }

    private var currentLanguageDisplayName: String {
        SaneAppLanguageSupport.currentLanguageDisplayName(bundle: bundle)
    }

    private var changeButton: some View {
        Button(labels.changeButtonTitle) {
            if let openLanguageSettings {
                openLanguageSettings()
                return
            }

            guard let url = SaneAppLanguageSupport.systemSettingsURL else { return }
            SanePlatform.open(url)
        }
        .buttonStyle(SaneActionButtonStyle())
    }

    private func valueText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
    }
}
