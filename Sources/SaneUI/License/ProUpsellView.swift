import AppKit
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
    let feature: Feature
    @Bindable var licenseService: LicenseService
    /// Optional explicit close action (used when presented in a standalone window).
    /// When nil, falls back to SwiftUI's `dismiss` environment action (sheets).
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showingLicenseEntry = false

    public init(feature: Feature, licenseService: LicenseService, onClose: (() -> Void)? = nil) {
        self.feature = feature
        self.licenseService = licenseService
        self.onClose = onClose
    }

    private func closeView() {
        if let onClose { onClose() } else { dismiss() }
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Close button
            HStack {
                Spacer()
                Button { closeView() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            // Feature they tried
            VStack(spacing: 8) {
                Image(systemName: feature.featureIcon)
                    .font(.system(size: 36))
                    .foregroundStyle(.teal)

                Text(feature.featureName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(feature.featureDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()
                .padding(.horizontal, 20)

            // Value props
            VStack(alignment: .leading, spacing: 6) {
                proPoint(icon: "star.fill", text: "All Pro features unlocked")
                proPoint(icon: "infinity", text: "Lifetime updates — no subscription")
                proPoint(icon: "lock.shield", text: "100% on-device, no account required")
                proPoint(icon: "heart.fill", text: "Support independent development")
            }
            .padding(.horizontal, 10)

            // Price + CTA
            VStack(spacing: 8) {
                Text(licenseService.appStoreDisplayPrice ?? "$6.99")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.teal)

                Text("One-time purchase")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.92))

                if licenseService.usesAppStorePurchase {
                    Button {
                        Task { await licenseService.purchasePro() }
                    } label: {
                        Text(licenseService.isPurchasing ? "Processing..." : "Unlock Pro")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .controlSize(.large)
                    .disabled(licenseService.isPurchasing)

                    Button("Restore Purchases") {
                        Task { await licenseService.restorePurchases() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(licenseService.isPurchasing)
                } else {
                    Button {
                        if let url = licenseService.checkoutURL {
                            NSWorkspace.shared.open(url)
                        }
                        let appName = licenseService.appName.lowercased()
                        Task.detached {
                            await EventTracker.log("upsell_clicked_buy", app: appName)
                        }
                    } label: {
                        Text("Unlock Pro")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.teal)
                    .controlSize(.large)

                    Button("I Have a Key") {
                        showingLicenseEntry = true
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.teal)
                    .font(.system(size: 13))
                }

                if let purchaseError = licenseService.purchaseError {
                    Text(purchaseError)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(24)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .onExitCommand { closeView() }
        .sheet(isPresented: $showingLicenseEntry) {
            LicenseEntryView(licenseService: licenseService)
        }
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

    private func proPoint(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.teal)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
