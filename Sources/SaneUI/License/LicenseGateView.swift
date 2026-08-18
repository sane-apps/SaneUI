#if os(macOS)
import SwiftUI

public enum LicenseGateLayoutPolicy {
    public static let frameSize = CGSize(width: 520, height: 680)
}

/// Full-screen license gate that replaces the entire app window when unlicensed.
///
/// Shows either:
/// - direct checkout + key entry for website builds, or
/// - App Store IAP + restore for App Store builds.
/// The window stays closable. Not now continues without buying.
/// On successful activation, displays a checkmark animation and dismisses after 1.5 seconds.
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
        .frame(
            minWidth: LicenseGateLayoutPolicy.frameSize.width,
            minHeight: LicenseGateLayoutPolicy.frameSize.height
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .saneWindowContentSize(LicenseGateLayoutPolicy.frameSize)
        .onAppear {
            let appName = licenseService.appName.lowercased()
            Task.detached {
                await EventTracker.log(.paywallSeen, app: appName)
            }
        }
        .onChange(of: licenseService.isLicensed) { _, licensed in
            if licensed {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccess = true
                }
            }
        }
    }

    // MARK: - Gate View

    private var gateView: some View {
        VStack {
            Spacer(minLength: 18)

            VStack(spacing: 22) {
                gateHeader
                purchaseActions
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

            Text("Your 14-day trial has ended")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)

            Text("Buy \(licenseService.appName) once to keep using it.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var purchaseActions: some View {
        VStack(spacing: 12) {
            Button {
                let appName = licenseService.appName.lowercased()
                Task.detached {
                    await EventTracker.log(.checkoutClicked, app: appName)
                }
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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
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
                     ? "One-time in-app purchase"
                     : "\(licenseService.displayPriceLabel) \u{00B7} One-time purchase \u{00B7} Lifetime updates"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let error = licenseService.purchaseError {
                Text(error)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private var secondaryActions: some View {
        if licenseService.usesSetappPurchase {
            VStack(spacing: 10) {
                Text(licenseService.distributionChannel.purchaseManagementMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                continueWithoutPurchaseButton
                quitButton
            }
        } else if licenseService.usesAppStorePurchase {
            VStack(spacing: 10) {
                Button {
                    Task { await licenseService.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)

                continueWithoutPurchaseButton
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)

                continueWithoutPurchaseButton
                quitButton
            }
        }
    }

    private var continueWithoutPurchaseButton: some View {
        Button {
            let appName = licenseService.appName.lowercased()
            Task.detached {
                await EventTracker.log(.paywallDismissed, app: appName)
            }
            licenseService.continueWithoutPurchase()
        } label: {
            Text("Not now")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SaneActionButtonStyle())
        .controlSize(.small)
        .accessibilityIdentifier("license-gate-not-now")
    }

    private var quitButton: some View {
        Button {
            let appName = licenseService.appName.lowercased()
            Task.detached {
                await EventTracker.log(.paywallQuit, app: appName)
            }
            NSApplication.shared.terminate(nil)
        } label: {
            Text("Quit")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SaneActionButtonStyle())
        .controlSize(.small)
    }

    private var primaryPurchaseLabel: String {
        if licenseService.usesSetappPurchase {
            return "Managed by Setapp"
        }
        if licenseService.usesAppStorePurchase {
            return "Buy \(licenseService.appName) — \(licenseService.displayPriceLabel)"
        }
        return "Buy \(licenseService.appName)"
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
                        .font(.system(size: 14, weight: .medium))
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
