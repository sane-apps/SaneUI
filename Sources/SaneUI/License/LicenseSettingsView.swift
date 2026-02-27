import SwiftUI

/// Embeddable license settings section for app preferences.
///
/// - **Pro user:** Green checkmark + "Pro" badge + email + Deactivate button
/// - **Free user:** "Free" badge + "Unlock Pro — $6.99" button + "Enter Key" button
///
/// Drop into any app's Settings view.
public struct LicenseSettingsView: View {
    @Bindable var licenseService: LicenseService
    @State private var showingLicenseEntry = false

    public init(licenseService: LicenseService) {
        self.licenseService = licenseService
    }

    public var body: some View {
        if licenseService.isPro {
            licensedView
        } else {
            unlicensedView
        }
    }

    // MARK: - Licensed (Pro)

    private var licensedView: some View {
        Section("License") {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 16))
                Text("Pro")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                Spacer()
                if let email = licenseService.licenseEmail {
                    Text(email)
                        .foregroundStyle(.white.opacity(0.9))
                        .font(.caption)
                }
            }

            if licenseService.usesAppStorePurchase {
                Text("Managed by App Store")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))

                Button("Restore Purchases") {
                    Task { await licenseService.restorePurchases() }
                }
                .disabled(licenseService.isPurchasing)
            } else {
                Button("Deactivate License") {
                    licenseService.deactivate()
                }
                .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Unlicensed (Free)

    private var unlicensedView: some View {
        Section("License") {
            HStack(spacing: 8) {
                Image(systemName: "person.fill")
                    .foregroundStyle(.white.opacity(0.6))
                    .font(.system(size: 14))
                Text("Free")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                Spacer()

                if licenseService.usesAppStorePurchase {
                    Button {
                        Task { await licenseService.purchasePro() }
                    } label: {
                        Text(licenseService.isPurchasing
                                 ? "Processing..."
                                 : "Unlock Pro — \(licenseService.appStoreDisplayPrice ?? "$6.99")")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.saneAccent)
                    .controlSize(.small)
                    .disabled(licenseService.isPurchasing)
                } else {
                    Button {
                        if let url = licenseService.checkoutURL { NSWorkspace.shared.open(url) }
                    } label: {
                        Text("Unlock Pro — $6.99")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.saneAccent)
                    .controlSize(.small)
                }
            }

            HStack(spacing: 8) {
                if licenseService.usesAppStorePurchase {
                    Button("Restore Purchases") {
                        Task { await licenseService.restorePurchases() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.system(size: 12))
                    .disabled(licenseService.isPurchasing)
                } else {
                    Button("Enter Key") {
                        showingLicenseEntry = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .font(.system(size: 12))
                }

                if let error = licenseService.validationError ?? licenseService.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $showingLicenseEntry) {
            LicenseEntryView(licenseService: licenseService)
        }
        .task {
            if licenseService.usesAppStorePurchase {
                await licenseService.preloadAppStoreProduct()
            }
        }
    }
}
