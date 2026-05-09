#if os(macOS)
    public enum SaneAboutLicenseCatalog {
        public static var saneUI: SaneAboutView.LicenseEntry {
            SaneAboutView.LicenseEntry(
                name: "SaneUI",
                url: "https://github.com/sane-apps/SaneUI",
                text: "PolyForm Shield 1.0.0"
            )
        }

        public static var sparkle: SaneAboutView.LicenseEntry {
            SaneAboutView.LicenseEntry(
                name: "Sparkle",
                url: "https://sparkle-project.org",
                text: "MIT License"
            )
        }

        public static var keyboardShortcuts: SaneAboutView.LicenseEntry {
            SaneAboutView.LicenseEntry(
                name: "KeyboardShortcuts",
                url: "https://github.com/sindresorhus/KeyboardShortcuts",
                text: "MIT License"
            )
        }

        public static var hotKey: SaneAboutView.LicenseEntry {
            SaneAboutView.LicenseEntry(
                name: "HotKey",
                url: "https://github.com/soffes/HotKey",
                text: "MIT License"
            )
        }

        public static var whisperKit: SaneAboutView.LicenseEntry {
            SaneAboutView.LicenseEntry(
                name: "WhisperKit",
                url: "https://github.com/argmaxinc/WhisperKit",
                text: "MIT License"
            )
        }
    }
#endif
