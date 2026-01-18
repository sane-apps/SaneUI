import SwiftUI

/// Semantic SF Symbol constants for SaneApps
///
/// Use these instead of raw SF Symbol strings for consistency across all SaneApps.
///
/// ```swift
/// Image(systemName: SaneIcons.add)
/// Image(systemName: SaneIcons.success)
/// ```
public enum SaneIcons {
    // MARK: - Actions

    /// Add/create new item (plus)
    public static let add = "plus"

    /// Remove/delete item (trash)
    public static let remove = "trash"

    /// Edit item (pencil)
    public static let edit = "pencil"

    /// Duplicate/copy item (doc.on.doc)
    public static let duplicate = "doc.on.doc"

    /// Activate/enable (power)
    public static let activate = "power"

    /// Deactivate/disable (pause.circle)
    public static let deactivate = "pause.circle"

    /// Close/dismiss (xmark)
    public static let close = "xmark"

    /// Refresh/reload (arrow.clockwise)
    public static let refresh = "arrow.clockwise"

    // MARK: - Status

    /// Success state (checkmark.circle.fill)
    public static let success = "checkmark.circle.fill"

    /// Warning state (exclamationmark.triangle.fill)
    public static let warning = "exclamationmark.triangle.fill"

    /// Error state (xmark.circle.fill)
    public static let error = "xmark.circle.fill"

    /// Info state (info.circle.fill)
    public static let info = "info.circle.fill"

    // MARK: - Navigation

    /// Profiles/folders (folder.fill)
    public static let profiles = "folder.fill"

    /// Settings/preferences (gear)
    public static let settings = "gear"

    /// Back navigation (chevron.left)
    public static let back = "chevron.left"

    /// Forward navigation (chevron.right)
    public static let forward = "chevron.right"

    // MARK: - Content Types

    /// Network/connectivity (network)
    public static let network = "network"

    /// Web/globe (globe)
    public static let globe = "globe"

    /// Server/hosts (server.rack)
    public static let hosts = "server.rack"

    /// Protected/locked (lock.fill)
    public static let lock = "lock.fill"

    /// Unlocked (lock.open.fill)
    public static let unlock = "lock.open.fill"

    /// Document (doc.text)
    public static let document = "doc.text"

    /// Clipboard (doc.on.clipboard)
    public static let clipboard = "doc.on.clipboard"

    // MARK: - Data Operations

    /// Import data (arrow.down.circle)
    public static let `import` = "arrow.down.circle"

    /// Export data (arrow.up.circle)
    public static let export = "arrow.up.circle"

    /// Sync/refresh cycle (arrow.triangle.2.circlepath)
    public static let sync = "arrow.triangle.2.circlepath"

    /// Download (arrow.down.to.line)
    public static let download = "arrow.down.to.line"

    /// Upload (arrow.up.to.line)
    public static let upload = "arrow.up.to.line"

    // MARK: - Entry States

    /// Enabled entry (checkmark.circle)
    public static let entryEnabled = "checkmark.circle"

    /// Disabled entry (circle)
    public static let entryDisabled = "circle"

    // MARK: - Source Types

    /// Local source (externaldrive)
    public static let sourceLocal = "externaldrive"

    /// Remote/cloud source (cloud)
    public static let sourceRemote = "cloud"

    /// System source (gearshape)
    public static let sourceSystem = "gearshape"

    /// Inactive state (circle.dashed)
    public static let inactive = "circle.dashed"

    // MARK: - Templates

    /// Ad blocking (hand.raised.slash)
    public static let templateAdBlock = "hand.raised.slash"

    /// Development (hammer)
    public static let templateDev = "hammer"

    /// Social media (bubble.left.and.bubble.right)
    public static let templateSocial = "bubble.left.and.bubble.right"

    /// Privacy (eye.slash)
    public static let templatePrivacy = "eye.slash"

    // MARK: - UI Elements

    /// Menu bar (menubar.rectangle)
    public static let menuBar = "menubar.rectangle"

    /// Window (macwindow)
    public static let window = "macwindow"

    /// Sidebar (sidebar.left)
    public static let sidebar = "sidebar.left"

    /// List (list.bullet)
    public static let list = "list.bullet"

    /// Grid (square.grid.2x2)
    public static let grid = "square.grid.2x2"

    // MARK: - Miscellaneous

    /// Star/favorite (star.fill)
    public static let favorite = "star.fill"

    /// Heart/like (heart.fill)
    public static let heart = "heart.fill"

    /// Share (square.and.arrow.up)
    public static let share = "square.and.arrow.up"

    /// Search (magnifyingglass)
    public static let search = "magnifyingglass"

    /// Filter (line.3.horizontal.decrease.circle)
    public static let filter = "line.3.horizontal.decrease.circle"

    /// Sort (arrow.up.arrow.down)
    public static let sort = "arrow.up.arrow.down"
}
