import SwiftUI

/// Contextual upgrade modal shown when a free user tries a Pro action.
/// Shows the specific feature they tapped, value props, price, and CTA.
///
/// ```swift
/// .sheet(item: $proUpsellFeature) { feature in
///     ProUpsellView(feature: feature, licenseService: licenseService)
/// }
/// ```
public struct ProUpsellView<Feature: ProFeatureDescribing>: View {
    private enum Route {
        case upsell
        case licenseEntry
    }

    let feature: Feature
    @Bindable var licenseService: LicenseService
    /// Optional explicit close action (used when presented in a standalone window).
    /// When nil, falls back to SwiftUI's `dismiss` environment action (sheets).
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var route: Route = .upsell

    public init(feature: Feature, licenseService: LicenseService, onClose: (() -> Void)? = nil) {
        self.feature = feature
        self.licenseService = licenseService
        self.onClose = onClose
    }

    private func closeView() {
        if let onClose { onClose() } else { dismiss() }
    }

    private func handleKeyCommand(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let isCommandW = flags == [.command] &&
            event.charactersIgnoringModifiers?.lowercased() == "w"

        if event.keyCode == 53 {
            withAnimation(.easeInOut(duration: 0.2)) {
                if route == .licenseEntry {
                    route = .upsell
                    licenseService.validationError = nil
                } else {
                    closeView()
                }
            }
            return true
        }

        if isCommandW {
            closeView()
            return true
        }

        return false
    }
    public var body: some View {
#if os(macOS)
        proUpsellBody
            .saneOnKeyDown { handleKeyCommand($0) }
#else
        proUpsellBody
#endif
    }

    private var proUpsellBody: some View {
        Group {
            switch route {
            case .upsell:
                upsellContent
            case .licenseEntry:
                LicenseEntryView(
                    licenseService: licenseService,
                    onClose: { closeView() },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            route = .upsell
                            licenseService.validationError = nil
                        }
                    }
                )
            }
        }
        .saneOnExitCommand { closeView() }
        .onChange(of: licenseService.isPro) { _, newValue in
            if newValue { closeView() }
        }
        .onAppear {
            let appName = licenseService.appName.lowercased()
            Task.detached {
                await EventTracker.log("upsell_shown", app: appName)
            }
            if licenseService.usesAppStorePurchase {
                Task { await licenseService.preloadAppStoreProduct() }
            }
        }
    }

    @ViewBuilder
    private var dismissButton: some View {
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

    private var upsellContent: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                dismissButton
            }

            VStack(spacing: 8) {
                Image(systemName: feature.featureIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(Color.saneAccent)

                Text(feature.featureName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(feature.featureDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 6) {
                proPoint(icon: "star.fill", text: "All Pro features unlocked")
                proPoint(icon: "infinity", text: "Lifetime updates — no subscription")
                proPoint(icon: "lock.shield", text: "100% on-device, no account required")
                proPoint(icon: "heart.fill", text: "Helps keep new features coming")
            }
            .padding(.horizontal, 10)

            VStack(spacing: 8) {
                if licenseService.usesSetappPurchase {
                    Text("Setapp")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.saneAccent)

                    Text("Included with your Setapp install")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                } else {
                    Text(licenseService.displayPriceLabel)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.saneAccent)

                    Text("One-time purchase")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                }

                if licenseService.usesAppStorePurchase {
                    Button {
                        Task { await licenseService.purchasePro() }
                    } label: {
                        Text(licenseService.isPurchasing ? "Processing..." : "Unlock Pro — \(licenseService.displayPriceLabel)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(SaneActionButtonStyle(prominent: true))
                    .controlSize(.large)
                    .disabled(licenseService.isPurchasing)

                    Button("Restore Purchases") {
                        Task { await licenseService.restorePurchases() }
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                    .disabled(licenseService.isPurchasing)
                } else if licenseService.usesSetappPurchase {
                    Text("Included with Setapp")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 4)

                    Text(licenseService.distributionChannel.purchaseManagementMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Button {
                        if let url = licenseService.checkoutURL {
                            SanePlatform.open(url)
                        }
                        let appName = licenseService.appName.lowercased()
                        Task.detached {
                            await EventTracker.log("upsell_clicked_buy", app: appName)
                        }
                    } label: {
                        Text("Unlock Pro — \(licenseService.displayPriceLabel)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(SaneActionButtonStyle(prominent: true))
                    .controlSize(.large)

                    Button(licenseService.alternateEntryLabel) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            route = .licenseEntry
                            licenseService.validationError = nil
                        }
                    }
                    .buttonStyle(SaneActionButtonStyle())
                    .controlSize(.small)
                }

                if let purchaseError = licenseService.purchaseError {
                    Text(purchaseError)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(24)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func proPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.saneAccent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
