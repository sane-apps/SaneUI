# SaneUI

A shared SwiftUI design system for all SaneApps (SaneClip, SaneHosts, SaneBar, etc.).

## Features

- Glass morphism backgrounds with adaptive light/dark mode
- Consistent component library (sections, rows, toggles, badges)
- Semantic color and icon systems
- macOS 14+ optimized
- Swift 6 concurrency safe

## Installation

Add SaneUI to your Swift Package dependencies:

```swift
dependencies: [
    .package(path: "../SaneUI")  // Local path
    // or
    .package(url: "https://github.com/stephanjoseph/SaneUI", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["SaneUI"]
)
```

## Quick Start

```swift
import SwiftUI
import SaneUI

struct SettingsView: View {
    @State private var isEnabled = true

    var body: some View {
        ZStack {
            SaneGradientBackground()

            ScrollView {
                VStack(spacing: 20) {
                    CompactSection("General", icon: SaneIcons.settings, iconColor: .gray) {
                        CompactToggle(
                            label: "Enable Feature",
                            icon: "star",
                            iconColor: .yellow,
                            isOn: $isEnabled
                        )
                        CompactDivider()
                        CompactRow("Version", icon: "info.circle", iconColor: .blue) {
                            Text("1.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}
```

## Components

### Backgrounds

- `SaneGradientBackground` - Glass morphism background with adaptive colors
- `VisualEffectBlur` - macOS blur effect (NSVisualEffectView wrapper)
- `GlassGroupBoxStyle` - Glass morphism style for GroupBox

### Layout

- `CompactSection` - Grouped content with header, glass background, and shadow
- `CompactRow` - Standard row with icon, label, and trailing content
- `CompactToggle` - Toggle switch row with icon and label
- `CompactDivider` - Inset divider for separating rows

### Status

- `StatusBadge` - Rounded capsule badge for status indicators
- `ColorDot` - Small colored circle indicator
- `ActionButton` - Styled button with icon (primary, secondary, destructive)

### States

- `SaneEmptyState` - Empty view placeholder with icon, title, and action
- `SaneErrorState` - Error state with message and retry action
- `LoadingOverlay` - Semi-transparent loading indicator

## Colors

```swift
// Semantic colors
SaneColors.accent    // .teal
SaneColors.success   // .green
SaneColors.danger    // .red
SaneColors.warning   // .orange
SaneColors.info      // .blue

// Color extensions
Color.saneAccent
Color.saneSuccess
Color.saneDanger
Color.saneWarning
```

## Icons

Use `SaneIcons` for consistent SF Symbol usage:

```swift
Image(systemName: SaneIcons.add)        // plus
Image(systemName: SaneIcons.remove)     // trash
Image(systemName: SaneIcons.success)    // checkmark.circle.fill
Image(systemName: SaneIcons.settings)   // gear
// ... and many more
```

## Design Specifications

| Property | Value |
|----------|-------|
| Corner radius | 10pt |
| Horizontal padding | 12pt |
| Vertical padding | 10pt |
| Section gap | 20pt |
| Major gap | 24pt |

### Dark Mode
- Background: `.hudWindow` blur + teal gradient overlay
- Card fill: `white.opacity(0.08)`
- Border: `white.opacity(0.12)`
- Shadow: `black.opacity(0.15)`, 8pt radius

### Light Mode
- Background: Blue-gray gradient
- Card fill: `.white`
- Border: `teal.opacity(0.15)`
- Shadow: `teal.opacity(0.08)`, 6pt radius

## Requirements

- macOS 14.0+
- Swift 6.0+
- Xcode 16.0+

## Apps Using SaneUI

- **SaneClip** - Clipboard manager
- **SaneHosts** - Hosts file manager
- **SaneBar** - Menu bar manager

## License

MIT License - See LICENSE file for details.
