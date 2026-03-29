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
                    iconColor: licenseService.isPro ? .green : .white
                ) {
                    statusBadge(
                        title: licenseService.isPro ? "Pro" : "Basic",
                        color: licenseService.isPro ? .green : .white
                    )
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
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }
            }
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: licenseService.isPro ? "checkmark.seal.fill" : "person.fill")
                .foregroundStyle(licenseService.isPro ? .green : .white)
                .font(.system(size: 15))
            statusBadge(
                title: licenseService.isPro ? "Pro" : "Basic",
                color: licenseService.isPro ? .green : .white
            )
            Spacer()
            if let email = licenseService.licenseEmail {
                Text(email)
                    .foregroundStyle(.white)
                    .font(.system(size: 13, weight: .medium))
            }
        }
    }

    @ViewBuilder
    private var managementContent: some View {
        if let managementLabel = licenseService.distributionChannel.managementLabel {
            Text(managementLabel)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)

            if licenseService.usesAppStorePurchase {
                Button("Restore Purchases") {
                    Task { await licenseService.restorePurchases() }
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            }
        } else {
            Button(licenseService.accessManagementLabel) {
                licenseService.deactivate()
            }
            .buttonStyle(SaneActionButtonStyle(destructive: true))
            .controlSize(.small)
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
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            } else if licenseService.usesSetappPurchase {
                Text("Managed by Setapp")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            } else {
                Button(licenseService.alternateEntryLabel) {
                    showingLicenseEntry = true
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
            }

            if let error = licenseService.validationError ?? licenseService.purchaseError {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private var managementRow: some View {
        CompactRow("Actions", icon: "gearshape.2", iconColor: .white) {
            if licenseService.usesAppStorePurchase {
                Button("Restore Purchases") {
                    Task { await licenseService.restorePurchases() }
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            } else if licenseService.usesSetappPurchase {
                Text("Managed by Setapp")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            } else {
                Button(licenseService.accessManagementLabel) {
                    licenseService.deactivate()
                }
                .buttonStyle(SaneActionButtonStyle(destructive: true))
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var unlockRow: some View {
        CompactRow("Actions", icon: "cart", iconColor: .saneAccent) {
            HStack(spacing: 8) {
                unlockProButton

                if licenseService.usesAppStorePurchase {
                    Button("Restore Purchases") {
                        Task { await licenseService.restorePurchases() }
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                    .disabled(licenseService.isPurchasing)
                } else if licenseService.usesSetappPurchase {
                    Text("Managed by Setapp")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                } else {
                    Button(licenseService.alternateEntryLabel) {
                        showingLicenseEntry = true
                    }
                    .buttonStyle(SaneActionButtonStyle())
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
            } else if licenseService.usesSetappPurchase {
                Text("Included with Setapp")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                Button("Unlock Pro — $6.99") {
                    if let url = licenseService.checkoutURL {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        .buttonStyle(SaneActionButtonStyle(prominent: true))
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
