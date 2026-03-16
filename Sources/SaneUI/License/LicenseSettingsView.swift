#if os(macOS)
import SwiftUI

/// Embeddable license settings section for app preferences.
public struct LicenseSettingsView: View {
    public enum Style {
        case formSection
        case panel
    }

    @Bindable var licenseService: LicenseService
    @State private var showingLicenseEntry = false
    private let style: Style

    public init(licenseService: LicenseService, style: Style = .formSection) {
        self.licenseService = licenseService
        self.style = style
    }

    public var body: some View {
        Group {
            switch style {
            case .formSection:
                if licenseService.isPro {
                    licensedSection
                } else {
                    unlicensedSection
                }
            case .panel:
                panelContent
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

    private var licensedSection: some View {
        Section("License") {
            statusRow
            managementContent
        }
    }

    private var unlicensedSection: some View {
        Section("License") {
            statusRow
            unlockContent
        }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            CompactSection("License", icon: "key.fill", iconColor: .yellow) {
                CompactRow(
                    "Status",
                    icon: licenseService.isPro ? "checkmark.seal.fill" : "lock.open",
                    iconColor: licenseService.isPro ? .green : .secondary
                ) {
                    statusBadge(
                        title: licenseService.isPro ? "Pro" : "Basic",
                        color: licenseService.isPro ? .green : .secondary
                    )
                }

                if let email = licenseService.licenseEmail {
                    CompactDivider()
                    CompactRow("Activated For", icon: "envelope", iconColor: .blue) {
                        Text(email)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                CompactDivider()
                if licenseService.isPro {
                    managementRow
                } else {
                    unlockRow
                }
            }

            if let error = licenseService.validationError ?? licenseService.purchaseError {
                CompactSection("Status", icon: "exclamationmark.triangle.fill", iconColor: .red) {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
            }

            CompactSection("Privacy", icon: "lock.shield", iconColor: .green) {
                Text("This only checks whether your activation code is valid. It does not upload your files, profiles, or app content.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: licenseService.isPro ? "checkmark.seal.fill" : "person.fill")
                .foregroundStyle(licenseService.isPro ? .green : .white.opacity(0.6))
                .font(.system(size: 15))
            statusBadge(
                title: licenseService.isPro ? "Pro" : "Free",
                color: licenseService.isPro ? .green : .secondary
            )
            Spacer()
            if let email = licenseService.licenseEmail {
                Text(email)
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var managementContent: some View {
        if licenseService.usesAppStorePurchase {
            Text("Managed by App Store")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Button("Restore Purchases") {
                Task { await licenseService.restorePurchases() }
            }
            .disabled(licenseService.isPurchasing)
        } else {
            Button(LicenseService.deactivateLicenseLabel()) {
                licenseService.deactivate()
            }
            .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var unlockContent: some View {
        HStack(spacing: 8) {
            unlockProButton

            if licenseService.usesAppStorePurchase {
                Button("Restore Purchases") {
                    Task { await licenseService.restorePurchases() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .font(.system(size: 12))
                .disabled(licenseService.isPurchasing)
            } else {
                Button(LicenseService.keyEntryButtonLabel()) {
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

    private var managementRow: some View {
        CompactRow("Actions", icon: "gearshape.2", iconColor: .secondary) {
            if licenseService.usesAppStorePurchase {
                Button("Restore Purchases") {
                    Task { await licenseService.restorePurchases() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            } else {
                Button(LicenseService.deactivateLicenseLabel()) {
                    licenseService.deactivate()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.red)
            }
        }
    }

    private var unlockRow: some View {
        CompactRow("Actions", icon: "cart", iconColor: .saneAccent) {
            HStack(spacing: 8) {
                unlockProButton

                if licenseService.usesAppStorePurchase {
                    Button("Restore Purchases") {
                        Task { await licenseService.restorePurchases() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(licenseService.isPurchasing)
                } else {
                    Button(LicenseService.keyEntryButtonLabel()) {
                        showingLicenseEntry = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private var unlockProButton: some View {
        Group {
            if licenseService.usesAppStorePurchase {
                Button(licenseService.isPurchasing ? "Processing..." : "Unlock Pro — \(licenseService.appStoreDisplayPrice ?? "$6.99")") {
                    Task { await licenseService.purchasePro() }
                }
                .disabled(licenseService.isPurchasing)
            } else {
                Button("Unlock Pro — $6.99") {
                    if let url = licenseService.checkoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.saneAccent)
        .controlSize(.small)
    }

    private func statusBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
    }
}
#endif
