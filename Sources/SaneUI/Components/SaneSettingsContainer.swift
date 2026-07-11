import SwiftUI

#if os(macOS)
    import AppKit
#endif

private enum SaneSettingsWindowMetrics {
    static let minWidth: CGFloat = 560
    static let idealWidth: CGFloat = 600
    static let minHeight: CGFloat = 352
    static let idealHeight: CGFloat = 400
    static let sidebarMinWidth: CGFloat = 152
    static let sidebarIdealWidth: CGFloat = 168
    static let sidebarMaxWidth: CGFloat = 220
}

/// A tab definition for `SaneSettingsContainer`.
///
/// Each app defines its own tab enum conforming to `SaneSettingsTab`:
/// ```swift
/// enum MyTab: String, SaneSettingsTab {
///     case general = "General"
///     case about = "About"
///
///     var icon: String {
///         switch self {
///         case .general: "gear"
///         case .about: "questionmark.circle"
///         }
///     }
///
///     var iconColor: Color { .white }
/// }
/// ```
public protocol SaneSettingsTab: RawRepresentable, CaseIterable, Identifiable, Hashable
where RawValue == String, AllCases: RandomAccessCollection {
    var title: String { get }
    var icon: String { get }
    var iconColor: Color { get }
}

public extension SaneSettingsTab {
    var id: String { rawValue }
    var title: String { rawValue }
}

public enum SaneSettingsWindowDefaults {
    public static let minWidth: CGFloat = SaneSettingsWindowMetrics.minWidth
    public static let idealWidth: CGFloat = SaneSettingsWindowMetrics.idealWidth
    public static let minHeight: CGFloat = SaneSettingsWindowMetrics.minHeight
    public static let idealHeight: CGFloat = SaneSettingsWindowMetrics.idealHeight
}

public enum SaneSettingsWindowSizingBehavior {
    case standalone
    case embedded
}

/// Standardized settings window container with sidebar navigation.
///
/// Provides: deterministic dark sidebar with icons + colors, gradient background,
/// glass group box style, and consistent window sizing with a tighter default footprint.
///
/// ```swift
/// SaneSettingsContainer(defaultTab: MyTab.general) { tab in
///     switch tab {
///     case .general: GeneralSettingsView()
///     case .about: SaneAboutView(appName: "MyApp", githubRepo: "MyApp")
///     }
/// }
/// ```
public struct SaneSettingsContainer<Tab: SaneSettingsTab, Detail: View>: View {
    @State private var internalSelectedTab: Tab?
    @State private var didRevealInitialSidebarSelection = false
    private let defaultTab: Tab
    private let externalSelection: Binding<Tab?>?
    private let windowSizing: SaneSettingsWindowSizingBehavior
    private let detail: (Tab) -> Detail

    public init(
        defaultTab: Tab,
        windowSizing: SaneSettingsWindowSizingBehavior = .standalone,
        @ViewBuilder detail: @escaping (Tab) -> Detail
    ) {
        self.defaultTab = defaultTab
        _internalSelectedTab = State(initialValue: defaultTab)
        externalSelection = nil
        self.windowSizing = windowSizing
        self.detail = detail
    }

    public init(
        defaultTab: Tab,
        selection: Binding<Tab?>,
        windowSizing: SaneSettingsWindowSizingBehavior = .standalone,
        @ViewBuilder detail: @escaping (Tab) -> Detail
    ) {
        self.defaultTab = defaultTab
        _internalSelectedTab = State(initialValue: defaultTab)
        externalSelection = selection
        self.windowSizing = windowSizing
        self.detail = detail
    }

    public var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1)
            detail(selection.wrappedValue ?? defaultTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(SaneSettingsBackground())
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .tint(SanePanelChrome.accentStart)
        .modifier(SaneSettingsWindowSizingModifier(windowSizing: windowSizing))
        #if os(macOS)
            .background(windowSizingBackground)
        #endif
            .onAppear {
                if selection.wrappedValue == nil {
                    selection.wrappedValue = defaultTab
                }
            }
    }

    private var selection: Binding<Tab?> {
        externalSelection ?? $internalSelectedTab
    }

    private var sidebar: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(Tab.allCases), id: \.id) { tab in
                        Button {
                            selection.wrappedValue = tab
                        } label: {
                            Label {
                                Text(tab.title)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            } icon: {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(tab.iconColor)
                                    .frame(width: 20)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(selection.wrappedValue == tab ? SanePanelChrome.accentStart.opacity(0.34) : .clear)
                            }
                        }
                        .buttonStyle(.plain)
                        .saneHelp(tab.title)
                        .accessibilityAddTraits(selection.wrappedValue == tab ? .isSelected : [])
                        .id(tab.id)
                    }
                }
                .padding(8)
            }
            .onAppear {
                guard !didRevealInitialSidebarSelection else { return }
                didRevealInitialSidebarSelection = true
                proxy.scrollTo((selection.wrappedValue ?? defaultTab).id, anchor: .center)
            }
            .onChange(of: selection.wrappedValue) { _, selectedTab in
                guard let selectedTab else { return }
                proxy.scrollTo(selectedTab.id, anchor: .center)
            }
        }
        .frame(
            minWidth: SaneSettingsWindowMetrics.sidebarMinWidth,
            idealWidth: SaneSettingsWindowMetrics.sidebarIdealWidth,
            maxWidth: SaneSettingsWindowMetrics.sidebarMaxWidth,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            ZStack {
                SaneSettingsBackground()
                SanePanelChrome.controlNavyDeep.opacity(0.62)
            }
        )
    }

    #if os(macOS)
        @ViewBuilder
        private var windowSizingBackground: some View {
            if windowSizing == .standalone {
                SaneSettingsWindowConfigurator(
                    minContentSize: NSSize(
                        width: SaneSettingsWindowMetrics.minWidth,
                        height: SaneSettingsWindowMetrics.minHeight
                    ),
                    idealContentSize: NSSize(
                        width: SaneSettingsWindowMetrics.idealWidth,
                        height: SaneSettingsWindowMetrics.idealHeight
                    )
                )
            }
        }
    #endif
}

/// A pure SwiftUI background for settings hosts. Native `Settings {}` windows
/// on macOS 26 can intermittently fail to composite NSVisualEffectView-backed
/// backgrounds over SwiftUI controls, so this intentionally does not use the
/// shared mesh/blur background.
private struct SaneSettingsBackground: View {
    var body: some View {
        LinearGradient(
            colors: [SanePalette.navyDeep, SanePalette.tealGlowPanel, SanePalette.navyMid],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct SaneSettingsWindowSizingModifier: ViewModifier {
    let windowSizing: SaneSettingsWindowSizingBehavior

    func body(content: Content) -> some View {
        switch windowSizing {
        case .standalone:
            content.frame(
                minWidth: SaneSettingsWindowMetrics.minWidth,
                idealWidth: SaneSettingsWindowMetrics.idealWidth,
                minHeight: SaneSettingsWindowMetrics.minHeight,
                idealHeight: SaneSettingsWindowMetrics.idealHeight
            )
        case .embedded:
            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

#if os(macOS)
    /// Shared settings host window for AppKit-based SaneApps.
    ///
    /// Native SwiftUI `Settings {}` scenes get standard AppKit responder-chain paste
    /// behavior for free. Menu-bar apps that host settings in a custom `NSWindow`
    /// should use this class so text-entry views receive Cmd+V consistently.
    public final class SaneSettingsWindow: NSWindow, @unchecked Sendable {
        override public var canBecomeKey: Bool { true }
        override public var canBecomeMain: Bool { true }

        override public func performKeyEquivalent(with event: NSEvent) -> Bool {
            if Self.isPlainCommandV(event), forwardPasteToFirstResponder() {
                return true
            }

            return super.performKeyEquivalent(with: event)
        }

        override public func keyDown(with event: NSEvent) {
            if Self.isPlainCommandV(event), forwardPasteToFirstResponder() {
                return
            }

            super.keyDown(with: event)
        }

        private func forwardPasteToFirstResponder() -> Bool {
            if let firstResponder, firstResponder.tryToPerform(#selector(NSText.paste(_:)), with: self) {
                return true
            }

            return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
        }

        private static func isPlainCommandV(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return flags.contains(.command) &&
                flags.isDisjoint(with: [.option, .control]) &&
                (event.keyCode == 9 || event.charactersIgnoringModifiers?.lowercased() == "v")
        }
    }

    public struct SaneSettingsResizeGrip: NSViewRepresentable {
        public init() {}

        public func makeNSView(context: Context) -> SaneSettingsResizeGripView {
            SaneSettingsResizeGripView()
        }

        public func updateNSView(_ nsView: SaneSettingsResizeGripView, context: Context) {
            nsView.needsDisplay = true
        }
    }

    public final class SaneSettingsResizeGripView: NSView {
        private var initialFrame: NSRect?
        private var initialMouseLocation: NSPoint?

        override public var isFlipped: Bool { false }

        override public init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer?.backgroundColor = NSColor.clear.cgColor
            setAccessibilityRole(.handle)
            setAccessibilityLabel("Resize Settings window")
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func resetCursorRects() {
            super.resetCursorRects()
            addCursorRect(bounds, cursor: .resizeLeftRight)
        }

        override public func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            guard let context = NSGraphicsContext.current?.cgContext else { return }

            context.setStrokeColor(NSColor.white.withAlphaComponent(0.36).cgColor)
            context.setLineWidth(1.2)
            context.setLineCap(.round)

            let offsets: [CGFloat] = [5, 9, 13]
            for offset in offsets {
                context.move(to: CGPoint(x: bounds.maxX - offset, y: bounds.minY + 4))
                context.addLine(to: CGPoint(x: bounds.maxX - 4, y: bounds.minY + offset))
            }
            context.strokePath()
        }

        override public func mouseDown(with event: NSEvent) {
            guard let window else { return }
            initialFrame = window.frame
            initialMouseLocation = NSEvent.mouseLocation
        }

        override public func mouseDragged(with event: NSEvent) {
            guard let window,
                  let initialFrame,
                  let initialMouseLocation
            else { return }

            let current = NSEvent.mouseLocation
            let deltaX = current.x - initialMouseLocation.x
            let deltaY = current.y - initialMouseLocation.y

            var frame = initialFrame
            let minFrameSize = window.frameRect(
                forContentRect: NSRect(origin: .zero, size: window.contentMinSize)
            ).size
            frame.size.width = max(minFrameSize.width, initialFrame.width + deltaX)
            frame.size.height = max(minFrameSize.height, initialFrame.height - deltaY)
            frame.origin.y = initialFrame.maxY - frame.height
            window.setFrame(frame, display: true)
        }
    }

    private struct SaneSettingsWindowConfigurator: NSViewRepresentable {
        let minContentSize: NSSize
        let idealContentSize: NSSize

        func makeCoordinator() -> Coordinator {
            Coordinator()
        }

        func makeNSView(context _: Context) -> NSView {
            NSView(frame: .zero)
        }

        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async {
                guard let window = nsView.window else { return }
                context.coordinator.configure(
                    window: window,
                    minContentSize: minContentSize,
                    idealContentSize: idealContentSize
                )
            }
        }

        final class Coordinator {
            private var resizeAttemptsByWindow: [Int: Int] = [:]
            private let maxResizeAttempts = 3

            @MainActor
            func configure(window: NSWindow, minContentSize: NSSize, idealContentSize: NSSize) {
                let windowNumber = window.windowNumber
                let attempts = resizeAttemptsByWindow[windowNumber, default: 0]

                if !window.styleMask.contains(.fullSizeContentView) {
                    window.styleMask.insert(.fullSizeContentView)
                }
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                if #available(macOS 13.0, *) {
                    window.toolbarStyle = .unifiedCompact
                }
                window.contentMinSize = minContentSize

                let currentContentSize = window.contentRect(forFrameRect: window.frame).size
                let needsClamp = currentContentSize.width > idealContentSize.width + 1 ||
                    currentContentSize.height > idealContentSize.height + 1

                guard attempts == 0 || (needsClamp && attempts < maxResizeAttempts) else { return }
                resizeAttemptsByWindow[windowNumber] = attempts + 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    window.setContentSize(idealContentSize)
                }
            }
        }
    }
#endif
