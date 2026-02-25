import AppKit
import SwiftUI

/// Presents `ProUpsellView` in a standalone floating NSPanel.
/// Used from menu bar apps or borderless panels where `.sheet()` can't render.
///
/// ```swift
/// guard licenseService.isPro else {
///     ProUpsellWindow.show(feature: MyProFeature.snippets, licenseService: licenseService)
///     return
/// }
/// ```
@MainActor
public enum ProUpsellWindow {
    private static var window: NSPanel?
    private static var delegate: WindowDelegate?

    public static func show(feature: some ProFeatureDescribing, licenseService: LicenseService) {
        // Ensure only one panel instance at a time.
        if let existing = window {
            existing.close()
            window = nil
            delegate = nil
        }

        let upsellView = ProUpsellView(feature: feature, licenseService: licenseService, onClose: { close() })
        let hostingView = NSHostingView(rootView: upsellView)
        hostingView.setContentHuggingPriority(.required, for: .vertical)

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingView
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.title = "Unlock Pro"
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .windowBackgroundColor
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.becomesKeyOnlyIfNeeded = false

        // Hide traffic light buttons — the SwiftUI X (top-right) is the close mechanism
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        // Size to fit SwiftUI content
        let fittingSize = hostingView.fittingSize
        panel.setContentSize(fittingSize)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let windowDelegate = WindowDelegate(onClose: {
            window = nil
            delegate = nil
        })
        panel.delegate = windowDelegate
        delegate = windowDelegate

        window = panel
    }

    public static func close() {
        window?.close()
        window = nil
        delegate = nil
    }

    private final class WindowDelegate: NSObject, NSWindowDelegate, @unchecked Sendable {
        let onClose: () -> Void
        init(onClose: @escaping () -> Void) { self.onClose = onClose }
        func windowWillClose(_: Notification) {
            DispatchQueue.main.async { self.onClose() }
        }
    }
}
