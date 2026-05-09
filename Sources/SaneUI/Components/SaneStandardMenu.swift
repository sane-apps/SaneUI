#if os(macOS)
    import AppKit

    /// Standard AppKit menu items every SaneApps background utility should expose
    /// from its app menu, status-item menu, and Dock menu.
    @MainActor
    public enum SaneStandardMenu {
        public static let settingsTitle = "Settings..."
        public static let checkForUpdatesTitle = ["Check for", "Updates..."].joined(separator: " ")
        public static let licenseTitle = "License..."
        public static let aboutAndBugReportTitle = "About / Report a Bug..."
        public static let whatsNewTitle = "What's New..."

        /// Customer-critical utility actions every SaneApps background utility should expose
        /// in the same order from the app menu, menu bar item, and Dock menu when those surfaces exist.
        public static let coreUtilityOrder = [
            settingsTitle,
            licenseTitle,
            checkForUpdatesTitle,
            aboutAndBugReportTitle,
            whatsNewTitle,
        ]

        public static func openAppItem(
            appName: String,
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = ""
        ) -> NSMenuItem {
            item(
                title: "Open \(appName)",
                target: target,
                action: action,
                keyEquivalent: keyEquivalent
            )
        }

        public static func settingsItem(
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = ","
        ) -> NSMenuItem {
            item(
                title: settingsTitle,
                target: target,
                action: action,
                keyEquivalent: keyEquivalent,
                modifierMask: keyEquivalent.isEmpty ? [] : [.command]
            )
        }

        public static func checkForUpdatesItem(
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = ""
        ) -> NSMenuItem {
            item(
                title: checkForUpdatesTitle,
                target: target,
                action: action,
                keyEquivalent: keyEquivalent
            )
        }

        public static func licenseItem(
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = ""
        ) -> NSMenuItem {
            item(
                title: licenseTitle,
                target: target,
                action: action,
                keyEquivalent: keyEquivalent
            )
        }

        public static func aboutAndBugReportItem(
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = ""
        ) -> NSMenuItem {
            item(
                title: aboutAndBugReportTitle,
                target: target,
                action: action,
                keyEquivalent: keyEquivalent
            )
        }

        public static func whatsNewItem(
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = ""
        ) -> NSMenuItem {
            item(
                title: whatsNewTitle,
                target: target,
                action: action,
                keyEquivalent: keyEquivalent
            )
        }

        public static func quitItem(
            appName: String,
            target: AnyObject?,
            action: Selector,
            keyEquivalent: String = "q"
        ) -> NSMenuItem {
            item(
                title: "Quit \(appName)",
                target: target,
                action: action,
                keyEquivalent: keyEquivalent,
                modifierMask: keyEquivalent.isEmpty ? [] : [.command]
            )
        }

        public static func addCoreUtilityItems(
            to menu: NSMenu,
            appName: String,
            target: AnyObject?,
            settingsAction: Selector,
            licenseAction: Selector,
            checkForUpdatesAction: Selector? = nil,
            configureCheckForUpdates: ((NSMenuItem) -> Void)? = nil,
            aboutAndBugReportAction: Selector,
            whatsNewAction: Selector? = nil,
            extraUtilityItems: [NSMenuItem] = [],
            quitTarget: AnyObject? = nil,
            quitAction: Selector,
            settingsKeyEquivalent: String = ","
        ) {
            menu.addItem(settingsItem(
                target: target,
                action: settingsAction,
                keyEquivalent: settingsKeyEquivalent
            ))
            menu.addItem(licenseItem(target: target, action: licenseAction))

            if let checkForUpdatesAction {
                let updatesItem = checkForUpdatesItem(target: target, action: checkForUpdatesAction)
                configureCheckForUpdates?(updatesItem)
                menu.addItem(updatesItem)
            }

            menu.addItem(aboutAndBugReportItem(target: target, action: aboutAndBugReportAction))

            if let whatsNewAction {
                menu.addItem(whatsNewItem(target: target, action: whatsNewAction))
            }

            if !extraUtilityItems.isEmpty {
                menu.addItem(.separator())
                extraUtilityItems.forEach(menu.addItem)
            }

            menu.addItem(.separator())
            menu.addItem(quitItem(
                appName: appName,
                target: quitTarget ?? target,
                action: quitAction
            ))
        }

        public static func configureUpdateItem(
            _ item: NSMenuItem,
            isAvailable: Bool,
            unavailableStatus: String? = nil
        ) {
            item.isEnabled = isAvailable
            item.toolTip = isAvailable ? nil : unavailableStatus
        }

        public static func item(
            title: String,
            target: AnyObject?,
            action: Selector?,
            keyEquivalent: String = "",
            modifierMask: NSEvent.ModifierFlags = [],
            state: NSControl.StateValue = .off,
            isEnabled: Bool = true
        ) -> NSMenuItem {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
            item.target = target
            item.keyEquivalentModifierMask = modifierMask
            item.state = state
            item.isEnabled = isEnabled
            return item
        }
    }
#endif
