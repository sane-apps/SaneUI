import Foundation
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
        @Test("Settings chrome avoids NavigationSplitView in native Settings hosts")
        func settingsChromeUsesDeterministicSidebarLayout() throws {
            let source = try String(
                contentsOf: saneUIPackageRootURL()
                    .appendingPathComponent("Sources/SaneUI/Components/SaneSettingsContainer.swift"),
                encoding: .utf8
            )

            #expect(source.contains("HStack(spacing: 0)"))
            #expect(source.contains("selection.wrappedValue = tab"))
            #expect(source.contains("ScrollViewReader { proxy in"))
            #expect(source.contains("proxy.scrollTo((selection.wrappedValue ?? defaultTab).id, anchor: .center)"))
            #expect(source.contains(".onChange(of: selection.wrappedValue)"))
            #expect(!source.contains("NavigationSplitView"))
            #expect(source.contains("private struct SaneSettingsBackground: View"))
            #expect(source.contains("LinearGradient("))
            #expect(!source.contains("SaneGradientBackground"))
            #expect(!source.contains("VisualEffectBlur"))
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
