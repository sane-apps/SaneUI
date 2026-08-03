# SaneUI Agent Instructions

Follow `~/AGENTS.md` first (cross-LLM policy source of truth). This file carries SaneUI-specific facts.

Philosophy: `~/SaneApps/meta/Brand/NORTH_STAR.md`

## What Is SaneUI?

SaneUI is a Swift package plus a catalog app. It is the shared source of truth for settings chrome, About panes, license surfaces, updater rows, colors, and button styling across the SaneApps apps that ship shared UI.

Used by: SaneClick, SaneClip, SaneHosts, SaneSales, SaneVideo, and SaneBar (retired product, still a code consumer).

- Brand guidelines: `~/SaneApps/meta/Brand/SaneApps-Brand-Guidelines.md`
- Hooks/tooling: `~/SaneApps/infra/SaneProcess/`

## Project Structure

| Path | Purpose |
|------|---------|
| `Sources/SaneUI/` | Shared package code |
| `Sources/SaneUICatalog/` | Live catalog/source-of-truth app |
| `Tests/` | Unit tests |
| `Package.swift` | Swift Package manifest |

## Accent Source Of Truth

`Sources/SaneUI/Colors.swift` is the source of truth for app accent colors: `saneAccent` #0DA3C7 (plus `saneAccentDeep` #0F738F, `saneAccentSoft` #5CDBF2). This governs APP UI only — websites/marketing keep their own palettes.

## Quick Commands

```bash
# Build
swift build

# Test
swift test

# Add to a typical app repo Package.swift
.package(path: "../../infra/SaneUI")
```

## Shared UI Rules

- Check `Sources/SaneUICatalog/SaneUICatalogApp.swift` before changing any shared settings/About/license/update surface.
- Shared settings text, helper text, highlights, badges, status messages, and subsection text must stay bright white, high contrast, and at least `16pt` (`SaneTypography.bodySize`). Row labels use `SaneTypography.label`.
- Settings and right-click menu items must be ordered from the customer's most likely/common need to the least likely/most advanced need.
- Settings sections should use plain language, balanced spacing, and visual symmetry.
- Prefer frosted / liquid-glass rows (`SaneGlassRoundedBackground`) over a living mesh panel background. Flat linear backgrounds are a last-resort fallback only when glass cannot composite — never ship gray helper text or sub-16pt settings copy as part of that fallback.
- Do not wrap CompactToggle labels in `Button` — macOS control sizing shrinks absolute fonts inside buttons. Keep the tappable `HStack` + `onTapGesture` pattern in `Row.swift`.
- Do not reintroduce gray helper text, `mailto:` bug-report links, `Manage Access` copy, or `.buttonStyle(.bordered)` in shared surfaces.
- Prefer extending existing shared views over adding app-local one-offs.

## Adding Components

1. Create component in `Sources/SaneUI/Components/`
2. Add SwiftUI preview
3. Document public API
4. Run `swift test`
5. Update consuming apps if needed
