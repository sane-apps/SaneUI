import Foundation

public enum SaneAppLanguageSupport {
    public static let systemSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.Localization-Settings.extension"
    )

    public static func supportedLanguageCodes(localizations: [String]) -> [String] {
        var seen = Set<String>()
        return localizations.compactMap { localization in
            let normalized = normalizeLanguageCode(localization)
            guard normalized.isEmpty == false else { return nil }
            guard normalized.caseInsensitiveCompare("base") != .orderedSame else { return nil }
            guard seen.insert(normalized).inserted else { return nil }
            return normalized
        }
    }

    public static func selectedLanguageCode(
        supportedLanguageCodes: [String],
        preferredLanguageCodes: [String],
        developmentLocalization: String?
    ) -> String? {
        for preferred in preferredLanguageCodes {
            let normalizedPreferred = normalizeLanguageCode(preferred)
            if let match = supportedLanguageCodes.first(where: {
                normalizeLanguageCode($0) == normalizedPreferred
            }) {
                return match
            }
        }

        if let developmentLocalization {
            let normalizedDevelopment = normalizeLanguageCode(developmentLocalization)
            if let match = supportedLanguageCodes.first(where: {
                normalizeLanguageCode($0) == normalizedDevelopment
            }) {
                return match
            }
        }

        return supportedLanguageCodes.first
    }

    public static func supportedLanguageCodes(bundle: Bundle = .main) -> [String] {
        supportedLanguageCodes(localizations: bundle.localizations)
    }

    public static func currentLanguageCode(bundle: Bundle = .main) -> String? {
        selectedLanguageCode(
            supportedLanguageCodes: supportedLanguageCodes(bundle: bundle),
            preferredLanguageCodes: bundle.preferredLocalizations,
            developmentLocalization: bundle.developmentLocalization
        )
    }

    public static func currentLanguageDisplayName(
        bundle: Bundle = .main,
        displayLocale: Locale = .current
    ) -> String {
        let fallbackCode = bundle.developmentLocalization ?? "en"
        return displayName(
            for: currentLanguageCode(bundle: bundle) ?? fallbackCode,
            displayLocale: displayLocale
        )
    }

    public static func canChangeAppLanguage(bundle: Bundle = .main) -> Bool {
        supportedLanguageCodes(bundle: bundle).count > 1
    }

    public static func displayName(for languageCode: String, displayLocale: Locale = .current) -> String {
        let normalized = normalizeLanguageCode(languageCode)
        let identifier = normalized.replacingOccurrences(of: "_", with: "-")

        if let localizedIdentifier = displayLocale.localizedString(forIdentifier: identifier) {
            return localizedIdentifier.localizedCapitalized
        }

        if let localizedCode = displayLocale.localizedString(forLanguageCode: normalized) {
            return localizedCode.localizedCapitalized
        }

        return normalized.localizedCapitalized
    }

    private static func normalizeLanguageCode(_ languageCode: String) -> String {
        languageCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0 == "-" || $0 == "_" })
            .first
            .map { String($0).lowercased() } ?? ""
    }
}
