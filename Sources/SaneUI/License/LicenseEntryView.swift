#if os(macOS)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif
import SwiftUI

/// Simple license key entry form. Shown as a nested sheet from ProUpsellView or standalone.
/// Auto-dismisses 1.5s after successful activation with a checkmark animation.
public struct LicenseEntryView<Service: LicenseSettingsServiceProtocol>: View {
    @Bindable var licenseService: Service
    @Environment(\.dismiss) private var dismiss
    @State private var licenseKey = ""
    @State private var showingSuccess = false
    @State private var licenseFieldFocusRequest = 0
    @FocusState private var licenseFieldFocused: Bool
    #if os(macOS)
        @State private var previousActivationPolicy: NSApplication.ActivationPolicy?
        @State private var localPasteMonitor: Any?
        @State private var globalPasteMonitor: Any?
    #endif
    private let onClose: (() -> Void)?
    private let onBack: (() -> Void)?

    public init(
        licenseService: Service,
        onClose: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil
    ) {
        self.licenseService = licenseService
        self.onClose = onClose
        self.onBack = onBack
    }

    private func closeView() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func backOrDismiss() {
        if let onBack {
            onBack()
        } else {
            closeView()
        }
    }

    public var body: some View {
        #if os(macOS)
            licenseEntryBody
                .saneOnKeyDown { handleKeyCommand($0) }
        #else
            licenseEntryBody
        #endif
    }

    private var licenseEntryBody: some View {
        VStack(spacing: 16) {
            if showingSuccess {
                successContent
            } else if licenseService.usesSetappPurchase {
                setappContent
            } else if licenseService.usesAppStorePurchase {
                appStoreContent
            } else {
                entryContent
            }
        }
        .padding(24)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .saneOnExitCommand { closeView() }
        .onAppear {
            prepareTextEntryActivation()
        }
        .onDisappear {
            restoreTextEntryActivation()
        }
        .task {
            await focusLicenseField()
        }
        .onChange(of: licenseService.isPro) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    closeView()
                }
            }
        }
    }

    // MARK: - Success

    private var successContent: some View {
        Group {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Pro Activated!")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            if let email = licenseService.licenseEmail {
                Text(email)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Entry Form

    private var setappContent: some View {
        Group {
            HStack {
                Spacer()
                Button { closeView() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Managed by Setapp")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(licenseService.distributionChannel.purchaseManagementMessage)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appStoreContent: some View {
        Group {
            HStack {
                Spacer()
                Button { closeView() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Unlock Pro")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(licenseService.distributionChannel.purchaseManagementMessage)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(licenseService.isPurchasing ? "Processing..." : "Unlock Pro — \(licenseService.displayPriceLabel)") {
                Task { await licenseService.purchasePro() }
            }
            .buttonStyle(SaneActionButtonStyle(prominent: true))
            .disabled(licenseService.isPurchasing)

            Button("Restore Purchases") {
                Task { await licenseService.restorePurchases() }
            }
            .buttonStyle(SaneActionButtonStyle())
            .disabled(licenseService.isPurchasing)

            if let error = licenseService.purchaseError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task {
            await licenseService.preloadAppStoreProduct()
        }
    }

    private var entryContent: some View {
        Group {
            HStack {
                Spacer()
                Button { closeView() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text(licenseService.alternateEntryLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(licenseService.alternateEntryInstruction)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            ZStack {
                HStack(spacing: 8) {
                    licenseKeyInput

                    licensePasteButton
                }

                keyboardPasteShortcut
            }

            if let error = licenseService.validationError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button(onBack == nil ? "Cancel" : "Back") {
                    backOrDismiss()
                }
                .buttonStyle(SaneActionButtonStyle())
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("saneui-license-cancel")

                Button("Activate") {
                    Task {
                        await licenseService.activate(key: licenseKey)
                    }
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
                .disabled(licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || licenseService.isValidating)
                .accessibilityIdentifier("saneui-license-activate")

                if licenseService.isValidating {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    private var keyboardPasteShortcut: some View {
        Button("Paste License Key") {
            pasteLicenseKeyFromClipboard()
        }
        .keyboardShortcut("v", modifiers: .command)
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var licenseKeyInput: some View {
        #if os(macOS)
            SaneLicenseKeyTextField(
                text: $licenseKey,
                placeholder: "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
                focusRequest: licenseFieldFocusRequest,
                onPaste: pasteLicenseKeyFromClipboard
            )
            .frame(height: 24)
            .accessibilityIdentifier("saneui-license-key-field")
        #else
            TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $licenseKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .focused($licenseFieldFocused)
                .accessibilityIdentifier("saneui-license-key-field")
        #endif
    }

    @ViewBuilder
    private var licensePasteButton: some View {
        #if os(macOS)
            SaneLicensePasteButton(onPaste: pasteLicenseKeyFromClipboard)
                .frame(width: 35, height: 25)
        #else
            Button {
                pasteLicenseKeyFromClipboard()
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(SaneActionButtonStyle(compact: true))
            .accessibilityIdentifier("saneui-license-paste")
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Paste License Key")
            .help("Paste License Key")
        #endif
    }

    #if os(macOS)
        private func handleKeyCommand(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let isCommandV = flags.contains(.command) &&
                flags.intersection([.option, .control]).isEmpty &&
                (event.keyCode == 9 || event.charactersIgnoringModifiers?.lowercased() == "v")

            guard isCommandV else { return false }

            pasteLicenseKeyFromClipboard()
            return true
        }

        private func prepareTextEntryActivation() {
            SaneLicenseEditCommandTarget.shared.registerPasteHandler {
                pasteLicenseKeyFromClipboard()
            }
            SaneLicenseEditMenu.ensureInstalled()
            if previousActivationPolicy == nil {
                previousActivationPolicy = NSApp.activationPolicy()
            }
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            installPasteMonitors()
        }

        private func restoreTextEntryActivation() {
            removePasteMonitors()
            SaneLicenseEditCommandTarget.shared.clearPasteHandler()
            guard let previousActivationPolicy else { return }

            NSApp.setActivationPolicy(previousActivationPolicy)
            self.previousActivationPolicy = nil
        }

        private func installPasteMonitors() {
            guard localPasteMonitor == nil, globalPasteMonitor == nil else { return }

            localPasteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if handlePasteEvent(event) {
                    return nil
                }
                return event
            }
            globalPasteMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                guard isPasteEvent(event) else { return }
                Task { @MainActor in
                    pasteLicenseKeyFromClipboard()
                }
            }
        }

        private func removePasteMonitors() {
            if let localPasteMonitor {
                NSEvent.removeMonitor(localPasteMonitor)
                self.localPasteMonitor = nil
            }
            if let globalPasteMonitor {
                NSEvent.removeMonitor(globalPasteMonitor)
                self.globalPasteMonitor = nil
            }
        }

        private func handlePasteEvent(_ event: NSEvent) -> Bool {
            guard isPasteEvent(event) else { return false }

            pasteLicenseKeyFromClipboard()
            return true
        }

        private func isPasteEvent(_ event: NSEvent) -> Bool {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            return flags.contains(.command) &&
                flags.intersection([.option, .control]).isEmpty &&
                (event.keyCode == 9 || event.charactersIgnoringModifiers?.lowercased() == "v")
        }
    #else
        private func prepareTextEntryActivation() {}
        private func restoreTextEntryActivation() {}
    #endif

    @MainActor
    private func focusLicenseField() async {
        try? await Task.sleep(for: .milliseconds(150))
        guard !Task.isCancelled else { return }
        licenseFieldFocused = true
        licenseFieldFocusRequest += 1
    }

    @MainActor
    private func pasteLicenseKeyFromClipboard() {
        #if os(macOS)
            let pastedText = NSPasteboard.general.string(forType: .string)
        #elseif canImport(UIKit)
            let pastedText = UIPasteboard.general.string
        #else
            let pastedText: String? = nil
        #endif

        guard let pastedText else {
            licenseFieldFocused = true
            return
        }

        licenseKey = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        licenseFieldFocused = true
        licenseFieldFocusRequest += 1
    }
}

#if os(macOS)
    private struct SaneLicensePasteButton: NSViewRepresentable {
        let onPaste: @MainActor () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onPaste: onPaste)
        }

        func makeNSView(context: Context) -> NSButton {
            let button = NSButton()
            button.bezelStyle = .rounded
            button.isBordered = true
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "Paste License Key"
            )
            button.imagePosition = .imageOnly
            button.contentTintColor = .white
            button.target = context.coordinator
            button.action = #selector(Coordinator.pressPasteButton(_:))
            button.setAccessibilityIdentifier("saneui-license-paste")
            button.setAccessibilityLabel("Paste License Key")
            button.toolTip = "Paste License Key"
            return button
        }

        func updateNSView(_ button: NSButton, context: Context) {
            context.coordinator.onPaste = onPaste
            button.target = context.coordinator
            button.action = #selector(Coordinator.pressPasteButton(_:))
        }

        @MainActor
        final class Coordinator: NSObject {
            var onPaste: @MainActor () -> Void

            init(onPaste: @escaping @MainActor () -> Void) {
                self.onPaste = onPaste
            }

            @objc func pressPasteButton(_: Any?) {
                onPaste()
            }
        }
    }

    private struct SaneLicenseKeyTextField: NSViewRepresentable {
        @Binding var text: String
        let placeholder: String
        let focusRequest: Int
        let onPaste: @MainActor () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(text: $text)
        }

        func makeNSView(context: Context) -> PasteAwareTextField {
            let field = PasteAwareTextField()
            let cell = PasteAwareTextFieldCell(textCell: "")
            cell.owner = field
            field.cell = cell
            field.delegate = context.coordinator
            field.isBordered = true
            field.isBezeled = true
            field.bezelStyle = .roundedBezel
            field.drawsBackground = true
            field.backgroundColor = .textBackgroundColor
            field.textColor = .labelColor
            field.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            field.placeholderString = placeholder
            field.lineBreakMode = .byTruncatingTail
            field.usesSingleLineMode = true
            field.cell?.wraps = false
            field.cell?.isScrollable = true
            field.setAccessibilityIdentifier("saneui-license-key-field")
            field.onPaste = onPaste
            return field
        }

        func updateNSView(_ field: PasteAwareTextField, context: Context) {
            context.coordinator.text = $text
            field.onPaste = onPaste
            field.placeholderString = placeholder

            if field.stringValue != text {
                field.stringValue = text
            }

            guard context.coordinator.lastFocusRequest != focusRequest else { return }
            context.coordinator.lastFocusRequest = focusRequest
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }

        final class Coordinator: NSObject, NSTextFieldDelegate {
            var text: Binding<String>
            var lastFocusRequest = 0

            init(text: Binding<String>) {
                self.text = text
            }

            func controlTextDidChange(_ notification: Notification) {
                guard let field = notification.object as? NSTextField else { return }
                text.wrappedValue = field.stringValue
            }
        }

        final class PasteAwareTextField: NSTextField {
            var onPaste: (@MainActor () -> Void)?

            override func performKeyEquivalent(with event: NSEvent) -> Bool {
                if isPasteEvent(event) {
                    Task { @MainActor in
                        onPaste?()
                    }
                    return true
                }

                return super.performKeyEquivalent(with: event)
            }

            @MainActor
            func handlePasteCommand() {
                onPaste?()
            }

            private func isPasteEvent(_ event: NSEvent) -> Bool {
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                return flags.contains(.command) &&
                    flags.intersection([.option, .control]).isEmpty &&
                    (event.keyCode == 9 || event.charactersIgnoringModifiers?.lowercased() == "v")
            }
        }

        final class PasteAwareTextFieldCell: NSTextFieldCell {
            weak var owner: PasteAwareTextField?
            private let fieldEditor = PasteAwareFieldEditor()

            override func fieldEditor(for controlView: NSView) -> NSTextView? {
                guard controlView === owner else {
                    return super.fieldEditor(for: controlView)
                }

                fieldEditor.isFieldEditor = true
                fieldEditor.onPaste = { [weak owner] in
                    owner?.handlePasteCommand()
                }
                return fieldEditor
            }
        }

        final class PasteAwareFieldEditor: NSTextView {
            var onPaste: (@MainActor () -> Void)?

            override func performKeyEquivalent(with event: NSEvent) -> Bool {
                if isPasteEvent(event) {
                    handlePasteCommand()
                    return true
                }

                return super.performKeyEquivalent(with: event)
            }

            override func keyDown(with event: NSEvent) {
                if isPasteEvent(event) {
                    handlePasteCommand()
                    return
                }

                super.keyDown(with: event)
            }

            @MainActor
            private func handlePasteCommand() {
                onPaste?()
            }

            private func isPasteEvent(_ event: NSEvent) -> Bool {
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                return flags.contains(.command) &&
                    flags.intersection([.option, .control]).isEmpty &&
                    (event.keyCode == 9 || event.charactersIgnoringModifiers?.lowercased() == "v")
            }
        }
    }

    @MainActor
    private enum SaneLicenseEditMenu {
        static func ensureInstalled() {
            if NSApp.mainMenu == nil {
                NSApp.mainMenu = NSMenu()
            }

            guard let mainMenu = NSApp.mainMenu else { return }
            if mainMenu.item(withTitle: "Edit") != nil {
                updatePasteTarget()
                return
            }

            let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
            let editMenu = NSMenu(title: "Edit")
            editItem.submenu = editMenu

            editMenu.addItem(NSMenuItem(
                title: "Cut",
                action: #selector(NSText.cut(_:)),
                keyEquivalent: "x"
            ))
            editMenu.addItem(NSMenuItem(
                title: "Copy",
                action: #selector(NSText.copy(_:)),
                keyEquivalent: "c"
            ))
            let pasteItem = NSMenuItem(
                title: "Paste",
                action: #selector(SaneLicenseEditCommandTarget.paste(_:)),
                keyEquivalent: "v"
            )
            pasteItem.target = SaneLicenseEditCommandTarget.shared
            editMenu.addItem(pasteItem)
            editMenu.addItem(NSMenuItem.separator())
            editMenu.addItem(NSMenuItem(
                title: "Select All",
                action: #selector(NSText.selectAll(_:)),
                keyEquivalent: "a"
            ))

            let insertionIndex = min(1, mainMenu.items.count)
            mainMenu.insertItem(editItem, at: insertionIndex)
        }

        static func updatePasteTarget() {
            guard let editMenu = NSApp.mainMenu?.item(withTitle: "Edit")?.submenu,
                  let pasteItem = editMenu.item(withTitle: "Paste")
            else { return }

            pasteItem.action = #selector(SaneLicenseEditCommandTarget.paste(_:))
            pasteItem.target = SaneLicenseEditCommandTarget.shared
        }
    }

    @MainActor
    private final class SaneLicenseEditCommandTarget: NSObject {
        static let shared = SaneLicenseEditCommandTarget()

        private var pasteHandler: (() -> Void)?

        func registerPasteHandler(_ handler: @escaping () -> Void) {
            pasteHandler = handler
            SaneLicenseEditMenu.updatePasteTarget()
        }

        func clearPasteHandler() {
            pasteHandler = nil
        }

        @objc func paste(_: Any?) {
            pasteHandler?()
        }
    }
#endif
