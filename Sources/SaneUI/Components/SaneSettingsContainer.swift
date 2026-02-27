import SwiftUI

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

/// Standardized settings window container with sidebar navigation.
///
/// Provides: NavigationSplitView, sidebar with icons + colors, gradient background,
/// glass group box style, and consistent window sizing (700x450 minimum).
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
    @State private var selectedTab: Tab?
    private let defaultTab: Tab
    private let detail: (Tab) -> Detail

    public init(
        defaultTab: Tab,
        @ViewBuilder detail: @escaping (Tab) -> Detail
    ) {
        self.defaultTab = defaultTab
        _selectedTab = State(initialValue: defaultTab)
        self.detail = detail
    }

    public var body: some View {
        NavigationSplitView {
            List(Array(Tab.allCases), id: \.id, selection: $selectedTab) { tab in
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
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            ZStack {
                SaneGradientBackground()

                detail(selectedTab ?? defaultTab)
            }
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .frame(minWidth: 700, minHeight: 450)
    }
}
