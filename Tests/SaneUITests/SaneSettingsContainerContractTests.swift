import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
@testable import SaneUI
import Testing

#if canImport(AppKit)
    private func saneUIPackageRootURL(filePath: StaticString = #filePath) -> URL {
        URL(fileURLWithPath: "\(filePath)")
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    @Suite("Settings Container Shared Chrome")
    struct SaneSettingsContainerContractTests {
        @Test("Crowded settings rows stack controls without squeezing the label")
        @MainActor
        func crowdedRowsUseVerticalSpace() {
            func size(width: CGFloat) -> CGSize {
                let view = NSHostingView(rootView:
                    CompactRow("Per-app paste mode") {
                        Color.clear.frame(width: 340, height: 24)
                    }
                    .frame(width: width)
                    .fixedSize(horizontal: false, vertical: true)
                )
                return view.fittingSize
            }
            let wide = size(width: 700)
            let narrow = size(width: 400)
            #expect(narrow.width == 400)
            #expect(narrow.height >= wide.height + 20)
        }

        @Test("Settings chrome avoids NavigationSplitView in native Settings hosts")
        func settingsChromeUsesDeterministicSidebarLayout() throws {
            let source = try String(
                contentsOf: saneUIPackageRootURL()
                    .appendingPathComponent("Sources/SaneUI/Components/SaneSettingsContainer.swift"),
                encoding: .utf8
            )

            #expect(source.contains("HStack(spacing: 0)"))
            #expect(source.contains("selection.wrappedValue = tab"))
            #expect(source.contains(".contentShape(Rectangle())"))
            #expect(source.contains("ScrollViewReader { proxy in"))
            #expect(source.contains("proxy.scrollTo((selection.wrappedValue ?? defaultTab).id, anchor: .center)"))
            #expect(source.contains(".onChange(of: selection.wrappedValue)"))
            #expect(!source.contains("NavigationSplitView"))
            #expect(source.contains("private struct SaneSettingsBackground: View"))
            #expect(!source.contains("motion: .animated"))
            #expect(source.contains(".background(SaneSettingsBackground())"))
            #expect(source.contains(".environment(\\.font, SaneTypography.body)"))
            #expect(!source.contains("VisualEffectBlur"))
        }

        @Test("Settings chrome makes a fixed native window resizable without losing its close button")
        @MainActor
        func settingsChromeEnablesNativeResizing() {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 720, height: 600),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.isReleasedWhenClosed = false
            defer { window.close() }
            window.saneApplySettingsChrome(preferIdealSize: false)
            #expect(window.styleMask.contains(.resizable))
            #expect(window.styleMask.contains(.closable))
            #expect(window.contentMinSize == NSSize(width: 640, height: 400))
            #expect(window.contentMaxSize == NSSize(width: 960, height: 760))
        }

        @Test("Shared settings resize grip is owned by SaneUI")
        func sharedResizeGripIsOwnedBySaneUI() throws {
            let source = try String(
                contentsOf: saneUIPackageRootURL()
                    .appendingPathComponent("Sources/SaneUI/Components/SaneSettingsContainer.swift"),
                encoding: .utf8
            )

            #expect(source.contains("public struct SaneSettingsResizeGrip: NSViewRepresentable"))
            #expect(source.contains("public final class SaneSettingsResizeGripView: NSView"))
            #expect(source.contains("setAccessibilityLabel(\"Resize Settings window\")"))
            #expect(source.contains("window.setFrame(frame, display: true)"))
        }
    }
#endif
