# SaneUI

A shared SwiftUI design system for Sane Apps. Currently used by SaneBar.

## Features

- Glass morphism backgrounds with adaptive light/dark mode
- Semantic color system with adaptive tokens
- Shared SF Symbol constants
- macOS 14+ optimized
- Swift 6 concurrency safe

## Installation

Add SaneUI to your Swift Package dependencies:

```swift
dependencies: [
    .package(path: "../Projects/SaneUI")  // Local path (monorepo)
    // or
    .package(url: "https://github.com/sane-apps/SaneUI", from: "1.0.0")
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

            GroupBox("General") {
                Toggle("Enable Feature", isOn: $isEnabled)
            }
            .groupBoxStyle(GlassGroupBoxStyle())
            .padding(20)
        }
    }
}
```

## Components

### Backgrounds

- `SaneGradientBackground` - Glass morphism background with adaptive colors
- `VisualEffectBlur` - macOS blur effect (NSVisualEffectView wrapper)
- `GlassGroupBoxStyle` - Glass morphism style for GroupBox

### Colors

- `SaneColors` - Semantic colors (`accent`, `success`, `danger`, `warning`, `info`)
- `AdaptiveColors` - Light/dark adaptive card colors and shadows
  - `EnvironmentValues.adaptiveColors` provides access in SwiftUI

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

- **SaneBar** - Menu bar manager

## License

MIT License - See LICENSE file for details.

<!-- SANEAPPS_AI_CONTRIB_START -->
### Become a Contributor (Even if You Don't Code)

Are you tired of waiting on the dev to get around to fixing your problem?  
Do you have a great idea that could help everyone in the community, but think you can't do anything about it because you're not a coder?

Good news: you actually can.

Copy and paste this into Claude or Codex, then describe your bug or idea:

```text
I want to contribute to this repo, but I'm not a coder.

Repository:
https://github.com/sane-apps/SaneUI

Bug or idea:
[Describe your bug or idea here in plain English]

Please do this for me:
1) Understand and reproduce the issue (or understand the feature request).
2) Make the smallest safe fix.
3) Open a pull request to https://github.com/sane-apps/SaneUI
4) Give me the pull request link.
5) Open a GitHub issue in https://github.com/sane-apps/SaneUI/issues that includes:
   - the pull request link
   - a short summary of what changed and why
6) Also give me the exact issue link.

Important:
- Keep it focused on this one issue/idea.
- Do not make unrelated changes.
```

If needed, you can also just email the pull request link to hi@saneapps.com.

I review and test every pull request before merge.

If your PR is merged, I will publicly give you credit, and you'll have the satisfaction of knowing you helped ship a fix for everyone.
<!-- SANEAPPS_AI_CONTRIB_END -->
