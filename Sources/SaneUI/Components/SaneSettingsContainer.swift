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
///     var iconColor: Color {
///         switch self {
///         case .general: .gray
///         case .about: .secondary
///         }
///     }
/// }
/// ```
public protocol SaneSettingsTab: RawRepresentable, CaseIterable, Identifiable, Hashable
    where RawValue == String, AllCases: RandomAccessCollection {
    var icon: String { get }
    var iconColor: Color { get }
}

public extension SaneSettingsTab {
    var id: String { rawValue }
}

public enum SaneSettingsWindowDefaults {
    public static let minWidth: CGFloat = SaneSettingsWindowMetrics.minWidth
    public static let idealWidth: CGFloat = SaneSettingsWindowMetrics.idealWidth
    public static let minHeight: CGFloat = SaneSettingsWindowMetrics.minHeight
    public static let idealHeight: CGFloat = SaneSettingsWindowMetrics.idealHeight
}

/// Standardized settings window container with sidebar navigation.
///
/// Provides: NavigationSplitView, sidebar with icons + colors, gradient background,
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
    private let detail: (Tab) -> Detail

    public init(
        defaultTab: Tab,
        @ViewBuilder detail: @escaping (Tab) -> Detail
    ) {
        self.defaultTab = defaultTab
        _internalSelectedTab = State(initialValue: defaultTab)
        externalSelection = nil
        self.detail = detail
    }

    public init(
        defaultTab: Tab,
        selection: Binding<Tab?>,
        @ViewBuilder detail: @escaping (Tab) -> Detail
    ) {
        self.defaultTab = defaultTab
        _internalSelectedTab = State(initialValue: defaultTab)
        externalSelection = selection
        self.detail = detail
    }

    public var body: some View {
        NavigationSplitView {
            List(Array(Tab.allCases), id: \.id, selection: selection) { tab in
                NavigationLink(value: tab) {
                    Label {
                        Text(tab.rawValue)
                    } icon: {
                        Image(systemName: tab.icon)
                            .foregroundStyle(tab.iconColor)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(
                min: SaneSettingsWindowMetrics.sidebarMinWidth,
                ideal: SaneSettingsWindowMetrics.sidebarIdealWidth
            )
        } detail: {
            ZStack {
                SaneGradientBackground(style: .panel)

                detail(selection.wrappedValue ?? defaultTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .tint(SanePanelChrome.accentStart)
        .frame(
            minWidth: SaneSettingsWindowMetrics.minWidth,
            idealWidth: SaneSettingsWindowMetrics.idealWidth,
            minHeight: SaneSettingsWindowMetrics.minHeight,
            idealHeight: SaneSettingsWindowMetrics.idealHeight
        )
        #if os(macOS)
        .background(
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
        )
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
}

#if os(macOS)
private struct SaneSettingsWindowConfigurator: NSViewRepresentable {
    let minContentSize: NSSize
    let idealContentSize: NSSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
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
