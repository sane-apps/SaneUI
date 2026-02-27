import SwiftUI

// MARK: - Empty State

/// A centered empty state view with icon, title, description, and optional action.
///
/// Use this when a list or view has no content to display.
///
/// ```swift
/// SaneEmptyState(
///     icon: "folder",
///     title: "No Files",
///     description: "Add files to get started.",
///     actionTitle: "Add File"
/// ) {
///     // action
/// }
/// ```
public struct SaneEmptyState: View {
    let icon: String
    let title: String
    let description: String
    let actionTitle: String?
    let action: (() -> Void)?

    /// Creates a new empty state view
    /// - Parameters:
    ///   - icon: SF Symbol name for the icon
    ///   - title: The main title
    ///   - description: Supporting description text
    ///   - actionTitle: Optional action button title
    ///   - action: Optional action to perform
    public init(
        icon: String,
        title: String,
        description: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Color.saneAccent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading Overlay

/// A semi-transparent overlay with a progress indicator.
///
/// Use this during async operations to indicate loading state.
///
/// ```swift
/// MyView()
///     .overlay {
///         if isLoading {
///             LoadingOverlay(message: "Loading...")
///         }
///     }
/// ```
public struct LoadingOverlay: View {
    let message: String?

    /// Creates a new loading overlay
    /// - Parameter message: Optional loading message
    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                if let message = message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Error State

/// An error state view with icon, message, and retry action.
///
/// ```swift
/// SaneErrorState(
///     message: "Failed to load data",
///     retryTitle: "Try Again"
/// ) {
///     // retry action
/// }
/// ```
public struct SaneErrorState: View {
    let message: String
    let retryTitle: String?
    let retry: (() -> Void)?

    /// Creates a new error state view
    /// - Parameters:
    ///   - message: The error message
    ///   - retryTitle: Optional retry button title
    ///   - retry: Optional retry action
    public init(
        message: String,
        retryTitle: String? = nil,
        retry: (() -> Void)? = nil
    ) {
        self.message = message
        self.retryTitle = retryTitle
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: SaneIcons.error)
                .font(.system(size: 48))
                .foregroundStyle(.red)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryTitle = retryTitle, let retry = retry {
                Button(retryTitle, action: retry)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("States") {
    VStack {
        SaneEmptyState(
            icon: "folder",
            title: "No Items",
            description: "Add items to get started with your collection.",
            actionTitle: "Add Item"
        ) {
            print("Add tapped")
        }
    }
    .frame(width: 400, height: 300)
    .background(SaneGradientBackground())
}

#Preview("Loading") {
    ZStack {
        SaneGradientBackground()
        Text("Content behind overlay")
        LoadingOverlay(message: "Loading data...")
    }
    .frame(width: 400, height: 300)
}

#Preview("Error") {
    SaneErrorState(
        message: "Failed to connect to server",
        retryTitle: "Try Again"
    ) {
        print("Retry tapped")
    }
    .frame(width: 400, height: 300)
    .background(SaneGradientBackground())
}
