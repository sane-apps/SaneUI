import SwiftUI

/// Simple license key entry form. Shown as a nested sheet from ProUpsellView or standalone.
/// Auto-dismisses 1.5s after successful activation with a checkmark animation.
public struct LicenseEntryView: View {
    @Bindable var licenseService: LicenseService
    @Environment(\.dismiss) private var dismiss
    @State private var licenseKey = ""
    @State private var showingSuccess = false

    public init(licenseService: LicenseService) {
        self.licenseService = licenseService
    }

    public var body: some View {
        VStack(spacing: 16) {
            if showingSuccess {
                successContent
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
                    .foregroundStyle(.white.opacity(0.92))
            }
        }
    }

    // MARK: - Entry Form

    private var appStoreContent: some View {
        Group {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Unlock Pro")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text("This App Store build unlocks Pro with an in-app purchase.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(licenseService.isPurchasing ? "Processing..." : "Unlock Pro") {
                Task { await licenseService.purchasePro() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .disabled(licenseService.isPurchasing)

            Button("Restore Purchases") {
                Task { await licenseService.restorePurchases() }
            }
            .buttonStyle(.bordered)
            .disabled(licenseService.isPurchasing)

            if let error = licenseService.purchaseError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
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
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Text("Enter License Key")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Text("Paste the license key from your purchase confirmation email.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            TextField("XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", text: $licenseKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 13, design: .monospaced))

            if let error = licenseService.validationError {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .font(.system(size: 13))

                Button("Activate") {
                    Task {
                        await licenseService.activate(key: licenseKey)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .font(.system(size: 13))
                .disabled(licenseKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || licenseService.isValidating)

                if licenseService.isValidating {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }
}
