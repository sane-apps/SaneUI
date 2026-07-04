#if os(macOS)
import SwiftUI

/// Full-screen license gate that replaces the entire app window when unlicensed.
///
/// Shows either:
/// - direct checkout + key entry for website builds, or
/// - App Store IAP + restore for App Store builds.
/// On successful activation, displays a checkmark animation and dismisses after 1.5 seconds.
public struct LicenseGateView: View {
    @Bindable var licenseService: LicenseService
    let appIcon: String

    @State private var licenseKey = ""
    @State private var showKeyEntry = false
    @State private var showSuccess = false
    private static let donationURL = URL(string: "https://github.com/sponsors/MrSaneApps")!

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
        .frame(minWidth: 460, minHeight: 620)
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
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            Image(systemName: appIcon)
                .font(.system(size: 56))
                .foregroundStyle(Color.saneAccent)
                .shadow(color: Color.saneAccent.opacity(0.3), radius: 12)

            Text(licenseService.appName)
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                Text("Mr. Sane here. I need to share an insane stat with you all.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Across SaneApps Mac apps, there have been over 100,000 downloads in the last 180 days. Fewer than 0.5% resulted in a purchase.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)

                Text("Despite the many kind reviews and steady downloads, that is not sustainable.")
                    .font(.body)
                    .foregroundStyle(.white)

                VStack(spacing: 4) {
                    Text("\"The worker is worthy of his wages.\"")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .italic()

                    Text("1 Timothy 5:18")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(.vertical, 2)

                Text("If you love what I do and believe in privacy-first Mac apps, here's how you can help.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)

                Text("Sincerely,\nMr. Sane")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 2)
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 520)

            Spacer(minLength: 4)

            VStack(spacing: 12) {
                Button {
                    if licenseService.usesAppStorePurchase {
                        Task { await licenseService.purchasePro() }
                    } else if licenseService.usesSetappPurchase {
                        return
                    } else if let url = licenseService.checkoutURL {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    if licenseService.isPurchasing {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(primaryPurchaseLabel)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))
                .controlSize(.large)
                .disabled(licenseService.isPurchasing || licenseService.usesSetappPurchase)

                if showsDirectSupportActions {
                    Button {
                        NSWorkspace.shared.open(Self.donationURL)
                    } label: {
                        Text("Donate")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                }

                if licenseService.usesAppStorePurchase {
                    Button {
                        Task { await licenseService.restorePurchases() }
                    } label: {
                        Text("Restore Purchases")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                    .disabled(licenseService.isPurchasing)
                } else if licenseService.usesSetappPurchase {
                    Text(licenseService.distributionChannel.purchaseManagementMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showKeyEntry = true
                        }
                    } label: {
                        Text("Enter License")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                }

                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .foregroundStyle(.white)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)

                if let error = licenseService.purchaseError {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 320)

            Text(licenseService.usesSetappPurchase
                 ? "This Setapp build unlocks through Setapp."
                 : (licenseService.usesAppStorePurchase
                     ? "Unlock Pro in-app to continue"
                     : "\(licenseService.displayPriceLabel) \u{00B7} One-time purchase \u{00B7} Lifetime updates"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            Spacer(minLength: 12)
        }
        .padding(32)
    }

    private var showsDirectSupportActions: Bool {
        !licenseService.usesAppStorePurchase && !licenseService.usesSetappPurchase
    }

    private var primaryPurchaseLabel: String {
        if licenseService.usesSetappPurchase {
            return "Managed by Setapp"
        }
        if licenseService.usesAppStorePurchase {
            return "Unlock Pro — \(licenseService.displayPriceLabel)"
        }
        return "Buy Pro"
    }

    // MARK: - Key Entry View

    private var keyEntryView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.saneAccent)

            Text(licenseService.alternateEntryLabel)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(licenseService.alternateEntryInstruction)
                .font(.body)
                .foregroundStyle(.white)
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 16) {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showKeyEntry = false
                        licenseService.validationError = nil
                    }
                }
                .buttonStyle(SaneActionButtonStyle())

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
                .buttonStyle(SaneActionButtonStyle(prominent: true))
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
                    .foregroundStyle(.white)
            }

            Text("Thank you for supporting \(licenseService.appName).")
                .font(.body)
                .foregroundStyle(.white)

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
#endif
