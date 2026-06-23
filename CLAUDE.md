# SaneUI Project Configuration

> Shared UI components, styles, and brand assets for all Sane Apps

---

## Sane Philosophy

```
┌─────────────────────────────────────────────────────┐
│           BEFORE YOU SHIP, ASK:                     │
│                                                     │
│  1. Does this REDUCE fear or create it?             │
│  2. Power: Does user have control?                  │
│  3. Love: Does this help people?                    │
│  4. Sound Mind: Is this clear and calm?             │
│                                                     │
│  Grandma test: Would her life be better?            │
│                                                     │
│  "Not fear, but power, love, sound mind"            │
│  — 2 Timothy 1:7                                    │
└─────────────────────────────────────────────────────┘
```

→ Full philosophy: `~/SaneApps/meta/Brand/NORTH_STAR.md`

---

## Project Location

| Path | Description |
|------|-------------|
| **This project** | `~/SaneApps/infra/SaneUI/` |
| **Brand Guidelines** | `~/SaneApps/meta/Brand/SaneApps-Brand-Guidelines.md` |
| **Hooks/tooling** | `~/SaneApps/infra/SaneProcess/` |

**Used by:** SaneBar, SaneClick, SaneClip, SaneHosts, SaneSales, SaneSync, SaneVideo

---

## What is SaneUI?

SaneUI is a Swift package plus a catalog app. It is the shared source of truth
for settings chrome, About panes, license surfaces, updater rows, colors, and
button styling across the SaneApps apps that ship shared UI.

---

## Project Structure

| Path | Purpose |
|------|---------|
| `Sources/SaneUI/` | Shared package code |
| `Sources/SaneUICatalog/` | Live catalog/source-of-truth app |
| `Tests/` | Unit tests |
| `Package.swift` | Swift Package manifest |

---

## Quick Commands

```bash
# Build
swift build

# Test
swift test

# Add to a typical app repo Package.swift
.package(path: "../../infra/SaneUI")
```

---

## Shared UI Rules

- Check `Sources/SaneUICatalog/SaneUICatalogApp.swift` before changing any shared settings/About/license/update surface.
- Shared settings text, helper text, highlights, badges, status messages, and subsection text must stay bright white, high contrast, and at least `13pt`.
- Settings and right-click menu items must be ordered from the customer's most likely/common need to the least likely/most advanced need.
- Settings sections should use plain language, balanced spacing, and visual symmetry.
- Do not reintroduce gray helper text, `mailto:` bug-report links, `Manage Access` copy, or `.buttonStyle(.bordered)` in shared surfaces.
- Prefer extending existing shared views over adding app-local one-offs.

---

## Adding Components

1. Create component in `Sources/SaneUI/Components/`
2. Add SwiftUI preview
3. Document public API
4. Run `swift test`
5. Update consuming apps if needed
