// SaneUI - Shared Design System for SaneApps
// https://github.com/sane-apps/SaneUI

import SwiftUI
#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

/// SaneUI provides a cohesive design system for all SaneApps.
///
/// ## Quick Start
/// ```swift
/// import SaneUI
///
/// struct MyView: View {
///     var body: some View {
///         ZStack {
///             SaneGradientBackground()
///
///             CompactSection("Settings", icon: SaneIcons.settings, iconColor: .gray) {
///                 CompactToggle(label: "Enable Feature", icon: "star", iconColor: .yellow, isOn: $enabled)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Components
/// - ``SaneGradientBackground`` - Glass morphism background
/// - ``CompactSection`` - Grouped content with header
/// - ``CompactRow`` - Standard row with icon and content
/// - ``CompactToggle`` - Toggle switch row
/// - ``CompactDivider`` - Inset divider
/// - ``StatusBadge`` - Status indicator capsule
/// - ``SaneEmptyState`` - Empty view placeholder
/// - ``LoadingOverlay`` - Progress overlay
///
/// ## Colors
/// - ``SaneColors`` - Semantic color definitions
///
/// ## Icons
/// - ``SaneIcons`` - SF Symbol constants

// Re-export all public types
@_exported import struct SwiftUI.Color

@MainActor
enum SanePlatform {
    static func open(_ url: URL) {
        #if os(macOS)
            NSWorkspace.shared.open(url)
        #elseif os(iOS)
            UIApplication.shared.open(url)
        #endif
    }

    static func copyToPasteboard(_ string: String) {
        #if os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(string, forType: .string)
        #elseif os(iOS)
            UIPasteboard.general.string = string
        #endif
    }

    static var didBecomeActiveNotification: Notification.Name {
        #if os(macOS)
            NSApplication.didBecomeActiveNotification
        #elseif os(iOS)
            UIApplication.didBecomeActiveNotification
        #else
            Notification.Name("SanePlatformDidBecomeActive")
        #endif
    }
}

public extension View {
    @ViewBuilder
    func saneOnExitCommand(perform action: @escaping () -> Void) -> some View {
        #if os(macOS)
            self.onExitCommand(perform: action)
        #else
            self
        #endif
    }
}

#if os(macOS)
public extension View {
    @ViewBuilder
    func saneOnKeyDown(perform action: @escaping (NSEvent) -> Bool) -> some View {
        modifier(SaneKeyDownMonitor(action: action))
    }
}

private struct SaneKeyDownMonitor: ViewModifier {
    let action: (NSEvent) -> Bool
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil else { return }
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    action(event) ? nil : event
                }
            }
            .onDisappear {
                guard let monitor else { return }
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
    }
}
#endif
