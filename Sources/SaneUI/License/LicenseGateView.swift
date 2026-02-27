import SwiftUI

/// Full-screen license gate that replaces the entire app window when unlicensed.
///
/// Shows "Buy Now" and "I Have a Key" options. On successful activation,
/// displays a checkmark animation then dismisses after 1.5 seconds.
public struct LicenseGateView: View {
    @Bindable var licenseService: LicenseService
    let appIcon: String

    @State private var licenseKey = ""
    @State private var showKeyEntry = false
    @State private var showSuccess = false

    /// - Parameters:
    ///   - licenseService: The license service instance to validate against.
    ///   - appIcon: SF Symbol name for the app icon displayed at top.
    public init(licenseService: LicenseService, appIcon: String) {
        self.licenseService = licenseService
        self.appIcon = appIcon
    }

    public var body: some View {
        ZStack {
            SaneGradientBackground()

            if showSuccess {
                successView
                    .transition(.opacity)
            } else if showKeyEntry {
                keyEntryView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                gateView
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 420, minHeight: 460)
        .onAppear {
            lockWindow()
        }
        .onDisappear {
            // If the gate disappears but the user isn't licensed, quit.
            if !licenseService.isLicensed {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: licenseService.isLicensed) { _, licensed in
            if licensed {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                }
                // Restore close button after licensing so the window can close normally.
                if let window = NSApplication.shared.keyWindow {
                    window.styleMask.insert(.closable)
                }
            }
        }
    }

    /// Remove the close button so the gate can't be dismissed without a license.
    private func lockWindow() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible }) {
                window.styleMask.remove(.closable)
            }
        }
    }

    // MARK: - Gate View

    private var gateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: appIcon)
                .font(.system(size: 64))
                .foregroundStyle(.teal)
                .shadow(color: .teal.opacity(0.3), radius: 12)

            Text(licenseService.appName)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("Thank you for trying \(licenseService.appName).")
                    .font(.title3)
                    .foregroundStyle(.white)

                Text("Your free trial has ended.")
                    .font(.title3)
                    .foregroundStyle(.white)

                Text("To continue using \(licenseService.appName), please purchase a license.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if let url = licenseService.checkoutURL { NSWorkspace.shared.open(url) }
                } label: {
                    Text("Buy Now — $6.99")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .controlSize(.large)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showKeyEntry = true
                    }
                } label: {
                    Text("I Have a Key")
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 280)

            Text("$6.99 \u{00B7} One-time purchase \u{00B7} Lifetime updates")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Key Entry View

    private var keyEntryView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.teal)

            Text("Enter License Key")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Paste the license key from your purchase confirmation email.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $licenseKey)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: 360)
                    .onSubmit {
                        activateKey()
                    }

                if let error = licenseService.validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showKeyEntry = false
                        licenseService.validationError = nil
                    }
                }
                .buttonStyle(.bordered)

                Button {
                    activateKey()
                } label: {
                    if licenseService.isValidating {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 60)
                    } else {
                        Text("Activate")
                            .frame(width: 60)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || licenseService.isValidating)
            }

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: showSuccess)

            Text("Licensed!")
                .font(.title.bold())
                .foregroundStyle(.white)

            if let email = licenseService.licenseEmail {
                Text(email)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text("Thank you for supporting \(licenseService.appName).")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
        }
        .padding(32)
    }

    // MARK: - Actions

    private func activateKey() {
        Task {
            await licenseService.activate(key: licenseKey)
        }
    }
}
