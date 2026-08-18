import SwiftUI
#if os(macOS)
    import AppKit
#endif

/// Keeps a hosted SwiftUI canvas and its macOS window the same size.
///
/// Welcome and license surfaces use this so a 700x520 card cannot sit inside
/// a leftover 900x650 workspace window. Workspace views call the same helper
/// with `hugging: false` to unlock resize after onboarding.
public enum SaneWindowContentSync {
    public static let sizeTolerance: CGFloat = 8

    #if os(macOS)
        @MainActor
        public static var fillColor: NSColor {
            SanePalette.nsNavy
        }

        @MainActor
        public static func hug(_ window: NSWindow?, to contentSize: CGSize) {
            apply(window, contentSize: contentSize, hugging: true)
            guard let window else { return }
            let current = window.contentView?.frame.size ?? .zero
            guard shouldFitInitialCanvas(current, to: contentSize) else { return }
            window.setContentSize(contentSize)
            center(window)
        }

        @MainActor
        public static func release(_ window: NSWindow?, to contentSize: CGSize) {
            apply(window, contentSize: contentSize, hugging: false)
        }

        @MainActor
        public static func apply(_ window: NSWindow?, contentSize: CGSize, hugging: Bool) {
            guard let window else { return }

            window.backgroundColor = fillColor
            window.isOpaque = true

            if hugging {
                window.styleMask.insert(.fullSizeContentView)
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.isRestorable = false
                window.setFrameAutosaveName("")
                window.minSize = NSSize(width: contentSize.width, height: contentSize.height)
                window.maxSize = NSSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: CGFloat.greatestFiniteMagnitude
                )
                return
            }

            window.styleMask.remove(.fullSizeContentView)
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.isMovableByWindowBackground = false
            window.minSize = NSSize(
                width: min(800, contentSize.width),
                height: min(500, contentSize.height)
            )
            window.maxSize = NSSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
            let current = window.contentView?.frame.size ?? .zero
            if current.width + sizeTolerance < contentSize.width
                || current.height + sizeTolerance < contentSize.height {
                window.setContentSize(contentSize)
                center(window)
            }
        }

        public static func contentDelta(_ lhs: CGSize, _ rhs: CGSize) -> CGFloat {
            max(abs(lhs.width - rhs.width), abs(lhs.height - rhs.height))
        }

        /// First show may land in a leftover workspace frame. Shrink that once.
        public static func shouldFitInitialCanvas(_ current: CGSize, to contentSize: CGSize) -> Bool {
            current.width + sizeTolerance < contentSize.width
                || current.height + sizeTolerance < contentSize.height
                || current.width >= contentSize.width + 80
                || current.height >= contentSize.height + 80
        }

        @MainActor
        private static func center(_ window: NSWindow) {
            let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? window.frame
            let frame = NSRect(
                x: visible.midX - window.frame.width / 2,
                y: visible.midY - window.frame.height / 2,
                width: window.frame.width,
                height: window.frame.height
            )
            if abs(window.frame.origin.x - frame.origin.x) > sizeTolerance
                || abs(window.frame.origin.y - frame.origin.y) > sizeTolerance {
                window.setFrame(frame, display: true)
            }
        }
    #endif
}

public extension View {
    /// Match this view's hosting window to `size`.
    ///
    /// Pass `hugging: true` for onboarding/license canvases: first show
    /// matches the canvas, then the window can grow and the background
    /// fills. Pass `hugging: false` for the app workspace.
    func saneWindowContentSize(_ size: CGSize, hugging: Bool = true) -> some View {
        #if os(macOS)
            modifier(SaneWindowContentSizeModifier(size: size, hugging: hugging))
        #else
            self
        #endif
    }
}

#if os(macOS)
    private struct SaneWindowContentSizeModifier: ViewModifier {
        let size: CGSize
        let hugging: Bool

        func body(content: Content) -> some View {
            content.background(
                SaneWindowContentSyncAnchor(size: size, hugging: hugging)
            )
        }
    }

    private struct SaneWindowContentSyncAnchor: NSViewRepresentable {
        let size: CGSize
        let hugging: Bool

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        func makeNSView(context _: Context) -> NSView {
            let view = NSView(frame: .zero)
            view.isHidden = true
            return view
        }

        func updateNSView(_ view: NSView, context: Context) {
            fitIfNeeded(view.window, context: context)
            DispatchQueue.main.async {
                fitIfNeeded(view.window, context: context)
            }
        }

        private func fitIfNeeded(_ window: NSWindow?, context: Context) {
            if hugging, !context.coordinator.didFitInitialCanvas {
                SaneWindowContentSync.hug(window, to: size)
                context.coordinator.didFitInitialCanvas = true
                return
            }
            SaneWindowContentSync.apply(window, contentSize: size, hugging: hugging)
        }

        final class Coordinator {
            var didFitInitialCanvas = false
        }
    }
#endif
