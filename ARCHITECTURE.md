# SaneUI Architecture

Last updated: 2026-03-28

## Purpose

SaneUI is a Swift Package that provides the shared source of truth for SaneApps UI. It now covers:

- visual primitives: backgrounds, colors, icons
- shared settings shell: tabs, sections, rows, toggles
- shared settings surfaces: About, license, updater
- a standalone visual catalog used to inspect the current design system

## System Context

- **Swift Package** (`Package.swift`) consumed by macOS apps.
- **No runtime services** or persistence.
- **Pure SwiftUI components** and constants.

## Core Components

| Component | Responsibility | Key Files |
|---|---|---|
| SaneGradientBackground | Glass-like adaptive background | `Sources/SaneUI/Backgrounds.swift` |
| VisualEffectBlur | NSVisualEffectView wrapper | `Sources/SaneUI/Backgrounds.swift` |
| GlassGroupBoxStyle | GroupBox glass style | `Sources/SaneUI/Backgrounds.swift` |
| SaneColors | Semantic color palette | `Sources/SaneUI/Colors.swift` |
| AdaptiveColors | Light/dark adaptive tokens | `Sources/SaneUI/Colors.swift` |
| SaneIcons | SF Symbol constants | `Sources/SaneUI/Icons.swift` |
| SaneSettingsContainer | Shared settings tab shell | `Sources/SaneUI/Components/SaneSettingsContainer.swift` |
| CompactSection / CompactRow | Shared settings layout primitives | `Sources/SaneUI/Components/Section.swift`, `Sources/SaneUI/Components/Row.swift` |
| SaneAboutView | Shared About/support surface | `Sources/SaneUI/Components/SaneAboutView.swift` |
| LicenseSettingsView | Shared license surface | `Sources/SaneUI/License/LicenseSettingsView.swift` |
| SaneSparkleRow | Shared direct-update surface | `Sources/SaneUI/Components/SaneSparkleRow.swift` |
| SaneUICatalog | Standalone visual source-of-truth app | `Sources/SaneUICatalog/SaneUICatalogApp.swift` |

Channel invariant: shared About/license/update surfaces must be channel-aware. App Store consumers cannot inherit direct-download purchase, donation, GitHub Sponsors, crypto, Sparkle, or direct license-key paths through SaneUI defaults.

## Data and Persistence

SaneUI stays mostly view-driven. It has light app-facing state only where shared surfaces need it, such as:

- license state via `LicenseService`
- updater preferences via `SaneSparkleRow`
- diagnostics export via `SaneDiagnosticsService`

## State Machines

### Color Scheme Adaptation

```mermaid
stateDiagram-v2
  [*] --> Light
  [*] --> Dark
  Light --> Dark: system color scheme change
  Dark --> Light: system color scheme change
```

| State | Meaning | Entry | Exit |
|---|---|---|---|
| Light | Light mode colors/materials | system light scheme | scheme change |
| Dark | Dark mode colors/materials | system dark scheme | scheme change |

## Build and Release Truth

- **Build**: `swift build`
- **Test**: `swift test`
- **Distribution**: Swift Package (local path or GitHub)
- **Visual inspection**: `swift run SaneUICatalog`

## Testing Strategy

- Unit tests live in `Tests/SaneUITests/`.

## Risks and Tradeoffs

- Visual consistency still depends on app repos actually adopting shared surfaces.
- Changes affect all consuming apps; versioning must be handled carefully.
- If app repos redefine shared settings surfaces locally, design drift returns. The intended mitigation is to extend SaneUI, inspect the catalog first, and let SaneProcess drift checks block known clone patterns.
