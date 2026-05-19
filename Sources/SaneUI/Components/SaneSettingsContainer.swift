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
    where RawValue == String, AllCases: RandomAccessCollection
{
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
        NavigationSplitView {
            sidebar
        } detail: {
            ZStack {
                SaneGradientBackground(style: .panel)

                detail(selection.wrappedValue ?? defaultTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .navigationSplitViewStyle(.balanced)
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
        List(Array(Tab.allCases), id: \.id, selection: selection) { tab in
            NavigationLink(value: tab) {
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
            }
            .saneHelp(tab.title)
        }
        .listStyle(.sidebar)
        .scrollIndicators(.never)
        .scrollContentBackground(.hidden)
        .navigationSplitViewColumnWidth(
            min: SaneSettingsWindowMetrics.sidebarMinWidth,
            ideal: SaneSettingsWindowMetrics.sidebarIdealWidth,
            max: SaneSettingsWindowMetrics.sidebarMaxWidth
        )
        .background(
            ZStack {
                SaneGradientBackground(style: .panel)
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
                flags.intersection([.option, .control]).isEmpty &&
                (event.keyCode == 9 || event.charactersIgnoringModifiers?.lowercased() == "v")
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
