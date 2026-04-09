import SwiftUI

/// Simple license key entry form. Shown as a nested sheet from ProUpsellView or standalone.
/// Auto-dismisses 1.5s after successful activation with a checkmark animation.
public struct LicenseEntryView<Service: LicenseSettingsServiceProtocol>: View {
    @Bindable var licenseService: Service
    @Environment(\.dismiss) private var dismiss
    @State private var licenseKey = ""
    @State private var showingSuccess = false

    public init(licenseService: Service) {
        self.licenseService = licenseService
    }

    public var body: some View {
        VStack(spacing: 16) {
            if showingSuccess {
                successContent
            } else if licenseService.usesSetappPurchase {
                setappContent
            } else if licenseService.usesAppStorePurchase {
                appStoreContent
            } else {
                entryContent
            }
        }
        .padding(24)
        .frame(width: 400)
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: licenseService.isPro) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSuccess = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Success

    private var successContent: some View {
        Group {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Pro Activated!")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            if let email = licenseService.licenseEmail {
                Text(email)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Entry Form

    private var setappContent: some View {
        Group {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Managed by Setapp")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(licenseService.distributionChannel.purchaseManagementMessage)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appStoreContent: some View {
        Group {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Unlock Pro")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(licenseService.distributionChannel.purchaseManagementMessage)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(licenseService.isPurchasing ? "Processing..." : "Unlock Pro") {
                Task { await licenseService.purchasePro() }
            }
            .buttonStyle(SaneActionButtonStyle(prominent: true))
            .disabled(licenseService.isPurchasing)

            Button("Restore Purchases") {
                Task { await licenseService.restorePurchases() }
            }
            .buttonStyle(SaneActionButtonStyle())
            .disabled(licenseService.isPurchasing)

            if let error = licenseService.purchaseError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task {
            await licenseService.preloadAppStoreProduct()
        }
    }

    private var entryContent: some View {
        Group {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text(licenseService.alternateEntryLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text(licenseService.alternateEntryInstruction)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $licenseKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))
                .accessibilityIdentifier("saneui-license-key-field")

            if let error = licenseService.validationError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(SaneActionButtonStyle())
                .keyboardShortcut(.cancelAction)
                .accessibilityIdentifier("saneui-license-cancel")

                Button("Activate") {
                    Task {
                        await licenseService.activate(key: licenseKey)
                    }
                }
                .buttonStyle(SaneActionButtonStyle(prominent: true))
                .keyboardShortcut(.defaultAction)
                .disabled(licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || licenseService.isValidating)
                .accessibilityIdentifier("saneui-license-activate")

                if licenseService.isValidating {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }
}
