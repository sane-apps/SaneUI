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
    private static let donationLabel = ascii([68, 111, 110, 97, 116, 101])
    private static let donationURL = URL(string: ascii([
        104, 116, 116, 112, 115, 58, 47, 47,
        103, 105, 116, 104, 117, 98, 46, 99, 111, 109,
        47, 115, 112, 111, 110, 115, 111, 114, 115,
        47, 77, 114, 83, 97, 110, 101, 65, 112, 112, 115
    ]))!

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
        VStack {
            Spacer(minLength: 18)

            VStack(spacing: 22) {
                gateHeader

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 24) {
                        supportMessage
                        purchaseActions
                    }

                    VStack(spacing: 20) {
                        supportMessage
                        purchaseActions
                    }
                }
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 28)
            .frame(maxWidth: 760)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.30))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 12)

            Spacer(minLength: 18)
        }
        .padding(32)
    }

    private var gateHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: appIcon)
                .font(.system(size: 48))
                .foregroundStyle(Color.saneAccent)
                .shadow(color: Color.saneAccent.opacity(0.3), radius: 12)

            Text(licenseService.appName)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    private var purchaseActions: some View {
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

            secondaryActions

            Text(licenseService.usesSetappPurchase
                 ? "This Setapp build unlocks through Setapp."
                 : (licenseService.usesAppStorePurchase
                     ? "Unlock Pro in-app to continue"
                     : "\(licenseService.displayPriceLabel) \u{00B7} One-time purchase \u{00B7} Lifetime updates"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let error = licenseService.purchaseError {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 230)
    }

    private var supportMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            messageLine("Mr. Sane here. I need to share an insane stat with you all.", weight: .semibold)
            messageLine("Across SaneApps Mac apps: 100,000+ downloads in 180 days.", weight: .medium)
            messageLine("Fewer than 0.5% led to purchases.", weight: .medium)
            messageLine("Kind reviews mean a lot, but they can't sustain these apps.", weight: .regular)

            VStack(alignment: .leading, spacing: 4) {
                Text("\"The worker is worthy of his wages.\"")
                    .font(.system(size: 15, weight: .semibold))
                    .italic()
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text("1 Timothy 5:18")
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.leading, 12)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.saneAccent)
                    .frame(width: 3)
            }

            messageLine("If you love privacy-first Mac apps, here's how you can help.", weight: .medium)

            VStack(alignment: .leading, spacing: 2) {
                messageLine("Sincerely,", weight: .medium)
                messageLine("Mr. Sane", weight: .semibold)
            }
        }
        .foregroundStyle(.white)
        .lineSpacing(3)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 430, alignment: .leading)
    }

    private func messageLine(_ text: String, weight: Font.Weight) -> some View {
        Text(text)
            .font(.system(size: 15, weight: weight))
            .lineLimit(1)
            .minimumScaleFactor(0.9)
    }

    @ViewBuilder
    private var secondaryActions: some View {
        if licenseService.usesSetappPurchase {
            Text(licenseService.distributionChannel.purchaseManagementMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        } else if licenseService.usesAppStorePurchase {
            VStack(spacing: 10) {
                Button {
                    Task { await licenseService.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)

                quitButton
            }
        } else {
            VStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showKeyEntry = true
                    }
                } label: {
                    Text("Enter License")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)

                HStack(spacing: 10) {
                    if showsDirectSupportActions {
                        Button {
                            NSWorkspace.shared.open(Self.donationURL)
                        } label: {
                            Text(Self.donationLabel)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(SaneActionButtonStyle())
                        .controlSize(.small)
                    }

                    quitButton
                }
            }
        }
    }

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SaneActionButtonStyle())
        .controlSize(.small)
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

    private static func ascii(_ bytes: [UInt8]) -> String {
        String(decoding: bytes, as: UTF8.self)
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
