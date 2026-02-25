import Foundation

/// Protocol for app-specific Pro feature definitions.
///
/// Each app defines its own `enum ProFeature: String, ProFeatureDescribing, CaseIterable`
/// with features gated behind Pro. Used by `ProUpsellView` and `WelcomeGateView`.
///
/// ```swift
/// enum ProFeature: String, ProFeatureDescribing, CaseIterable {
///     case customScripts = "Custom Scripts"
///     var id: String { rawValue }
///     var featureName: String { rawValue }
///     var featureDescription: String { ... }
///     var featureIcon: String { ... }
/// }
/// ```
public protocol ProFeatureDescribing: Identifiable, Sendable {
    var featureName: String { get }
    var featureDescription: String { get }
    /// SF Symbol name.
    var featureIcon: String { get }
}
