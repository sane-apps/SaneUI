#if os(macOS)
import SwiftUI

/// Embeddable license settings section for app preferences.
public struct LicenseSettingsView<Service: LicenseSettingsServiceProtocol>: View {
    public enum Style {
        case formSection
        case panel
    }

    public struct Labels: Sendable {
        public let sectionTitle: String
        public let warningSectionTitle: String
        public let statusLabel: String
        public let actionsLabel: String
        public let basicBadgeTitle: String
        public let proBadgeTitle: String
        public let restorePurchasesLabel: String
        public let managedBySetappLabel: String
        public let includedWithSetappLabel: String
        public let processingLabel: String
        public let unlockProPrefix: String
        public let fallbackPriceLabel: String
        public let directEntryLabel: String?
        public let directManagementLabel: String?

        public init(
            sectionTitle: String,
            warningSectionTitle: String,
            statusLabel: String,
            actionsLabel: String,
            basicBadgeTitle: String,
            proBadgeTitle: String,
            restorePurchasesLabel: String,
            managedBySetappLabel: String,
            includedWithSetappLabel: String,
            processingLabel: String,
            unlockProPrefix: String,
            fallbackPriceLabel: String,
            directEntryLabel: String? = nil,
            directManagementLabel: String? = nil
        ) {
            self.sectionTitle = sectionTitle
            self.warningSectionTitle = warningSectionTitle
            self.statusLabel = statusLabel
            self.actionsLabel = actionsLabel
            self.basicBadgeTitle = basicBadgeTitle
            self.proBadgeTitle = proBadgeTitle
            self.restorePurchasesLabel = restorePurchasesLabel
            self.managedBySetappLabel = managedBySetappLabel
            self.includedWithSetappLabel = includedWithSetappLabel
            self.processingLabel = processingLabel
            self.unlockProPrefix = unlockProPrefix
            self.fallbackPriceLabel = fallbackPriceLabel
            self.directEntryLabel = directEntryLabel
            self.directManagementLabel = directManagementLabel
        }

        public static var `default`: Labels {
            Labels(
                sectionTitle: String(localized: "saneui.license.section_title", defaultValue: "License", bundle: .module),
                warningSectionTitle: String(localized: "saneui.license.warning_section_title", defaultValue: "Status", bundle: .module),
                statusLabel: String(localized: "saneui.license.status_label", defaultValue: "Status", bundle: .module),
                actionsLabel: String(localized: "saneui.license.actions_label", defaultValue: "Actions", bundle: .module),
                basicBadgeTitle: String(localized: "saneui.license.basic_badge_title", defaultValue: "Basic", bundle: .module),
                proBadgeTitle: String(localized: "saneui.license.pro_badge_title", defaultValue: "Pro", bundle: .module),
                restorePurchasesLabel: String(localized: "saneui.license.restore_purchases_label", defaultValue: "Restore Purchases", bundle: .module),
                managedBySetappLabel: String(localized: "saneui.license.managed_by_setapp_label", defaultValue: "Managed by Setapp", bundle: .module),
                includedWithSetappLabel: String(localized: "saneui.license.included_with_setapp_label", defaultValue: "Included with Setapp", bundle: .module),
                processingLabel: String(localized: "saneui.license.processing_label", defaultValue: "Processing...", bundle: .module),
                unlockProPrefix: String(localized: "saneui.license.unlock_pro_prefix", defaultValue: "Unlock Pro —", bundle: .module),
                fallbackPriceLabel: String(localized: "saneui.license.fallback_price_label", defaultValue: "$14.99", bundle: .module)
            )
        }

        func unlockProLabel(price: String?) -> String {
            "\(unlockProPrefix) \(price ?? fallbackPriceLabel)"
        }
    }

    @Bindable var licenseService: Service
    @State private var showingLicenseEntry = false
    private let style: Style
    private let labels: Labels

    public init(licenseService: Service, style: Style = .formSection, labels: Labels = .default) {
        self.licenseService = licenseService
        self.style = style
        self.labels = labels
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
            licenseService.checkCachedLicense()
            if licenseService.usesAppStorePurchase {
                await licenseService.preloadAppStoreProduct()
            }
        }
    }

    private var licensedSection: some View {
        Section(labels.sectionTitle) {
            statusRow
            managementContent
        }
    }

    private var unlicensedSection: some View {
        Section(labels.sectionTitle) {
            statusRow
            unlockContent
        }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            CompactSection(labels.sectionTitle, icon: "key.fill", iconColor: .yellow) {
                CompactRow(
                    labels.statusLabel,
                    icon: licenseService.isPro ? "checkmark.seal.fill" : "lock.open",
                    iconColor: licenseService.isPro ? .green : .white
                ) {
                    statusBadge(
                        title: licenseService.isPro ? labels.proBadgeTitle : labels.basicBadgeTitle,
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
                CompactSection(labels.warningSectionTitle, icon: "exclamationmark.triangle.fill", iconColor: .red) {
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
                title: licenseService.isPro ? labels.proBadgeTitle : labels.basicBadgeTitle,
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
                Button {
                    Task { await licenseService.restorePurchases() }
                } label: {
                    fittedActionLabel(labels.restorePurchasesLabel)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            }
        } else {
            Button {
                licenseService.deactivate()
            } label: {
                fittedActionLabel(labels.directManagementLabel ?? licenseService.accessManagementLabel)
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
                Button {
                    Task { await licenseService.restorePurchases() }
                } label: {
                    fittedActionLabel(labels.restorePurchasesLabel)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            } else if licenseService.usesSetappPurchase {
                Text(labels.managedBySetappLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            } else {
                Button {
                    showingLicenseEntry = true
                } label: {
                    fittedActionLabel(labels.directEntryLabel ?? licenseService.alternateEntryLabel)
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
        CompactRow(labels.actionsLabel, icon: "gearshape.2", iconColor: .white) {
            if licenseService.usesAppStorePurchase {
                Button {
                    Task { await licenseService.restorePurchases() }
                } label: {
                    fittedActionLabel(labels.restorePurchasesLabel)
                }
                .buttonStyle(SaneActionButtonStyle())
                .controlSize(.small)
                .disabled(licenseService.isPurchasing)
            } else if licenseService.usesSetappPurchase {
                Text(labels.managedBySetappLabel)
                    .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
            } else {
                Button {
                    licenseService.deactivate()
                } label: {
                    fittedActionLabel(labels.directManagementLabel ?? licenseService.accessManagementLabel)
                }
                .buttonStyle(SaneActionButtonStyle(destructive: true))
                .controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var unlockRow: some View {
        CompactRow(labels.actionsLabel, icon: "cart", iconColor: .saneAccent) {
            if licenseService.usesSetappPurchase {
                Text(labels.managedBySetappLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        unlockProButton
                        secondaryUnlockAction
                    }

                    VStack(alignment: .trailing, spacing: 8) {
                        unlockProButton
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        secondaryUnlockAction
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var unlockProButton: some View {
        Group {
            if licenseService.usesAppStorePurchase {
                Button {
                    Task { await licenseService.purchasePro() }
                } label: {
                    fittedActionLabel(
                        licenseService.isPurchasing
                            ? labels.processingLabel
                            : labels.unlockProLabel(price: licenseService.displayPriceLabel)
                    )
                }
                .disabled(licenseService.isPurchasing)
            } else if licenseService.usesSetappPurchase {
                Text(labels.includedWithSetappLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                Button {
                    if let url = licenseService.checkoutURL {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    fittedActionLabel(labels.unlockProLabel(price: licenseService.displayPriceLabel))
                }
            }
        }
        .buttonStyle(SaneActionButtonStyle(prominent: true))
        .controlSize(.small)
    }

    @ViewBuilder
    private var secondaryUnlockAction: some View {
        if licenseService.usesAppStorePurchase {
            Button {
                Task { await licenseService.restorePurchases() }
            } label: {
                fittedActionLabel(labels.restorePurchasesLabel)
            }
            .buttonStyle(SaneActionButtonStyle())
            .controlSize(.small)
            .disabled(licenseService.isPurchasing)
        } else {
            Button {
                showingLicenseEntry = true
            } label: {
                fittedActionLabel(labels.directEntryLabel ?? licenseService.alternateEntryLabel)
            }
            .buttonStyle(SaneActionButtonStyle())
            .controlSize(.small)
        }
    }

    private func fittedActionLabel(_ title: String) -> some View {
        Text(title)
            .lineLimit(1)
            .minimumScaleFactor(0.84)
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
