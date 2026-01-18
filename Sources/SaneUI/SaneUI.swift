// SaneUI - Shared Design System for SaneApps
// https://github.com/stephanjoseph/SaneUI

import SwiftUI

/// SaneUI provides a cohesive design system for all SaneApps.
///
/// ## Quick Start
/// ```swift
/// import SaneUI
///
/// struct MyView: View {
///     var body: some View {
///         ZStack {
///             SaneGradientBackground()
///
///             CompactSection("Settings", icon: SaneIcons.settings, iconColor: .gray) {
///                 CompactToggle(label: "Enable Feature", icon: "star", iconColor: .yellow, isOn: $enabled)
///             }
///         }
///     }
/// }
/// ```
///
/// ## Components
/// - ``SaneGradientBackground`` - Glass morphism background
/// - ``CompactSection`` - Grouped content with header
/// - ``CompactRow`` - Standard row with icon and content
/// - ``CompactToggle`` - Toggle switch row
/// - ``CompactDivider`` - Inset divider
/// - ``StatusBadge`` - Status indicator capsule
/// - ``SaneEmptyState`` - Empty view placeholder
/// - ``LoadingOverlay`` - Progress overlay
///
/// ## Colors
/// - ``SaneColors`` - Semantic color definitions
///
/// ## Icons
/// - ``SaneIcons`` - SF Symbol constants

// Re-export all public types
@_exported import struct SwiftUI.Color
