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

**Used by:** SaneBar, SaneClip, SaneVideo, SaneSync, SaneHosts, SaneAI, SaneScript

---

## What is SaneUI?

SaneUI is a **Swift Package** containing:
- Brand colors (Navy, Teal, Surface colors)
- Typography styles (SF Pro Display scale)
- Reusable SwiftUI components
- SwiftUI extensions

All Sane Apps import this package to maintain visual consistency.

---

## Project Structure

| Path | Purpose |
|------|---------|
| `Sources/SaneUI/Colors/` | Brand color definitions |
| `Sources/SaneUI/Typography/` | Font styles |
| `Sources/SaneUI/Components/` | Reusable UI components |
| `Sources/SaneUI/Extensions/` | SwiftUI extensions |
| `Tests/` | Unit tests |
| `Package.swift` | Swift Package manifest |

---

## Quick Commands

```bash
# Build
swift build

# Test
swift test

# Add to an app's Package.swift
.package(path: "../../../infra/SaneUI")
```

---

## Brand Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Navy** | `#1a2744` | Logo background, dark surfaces |
| **Glowing Teal** | `#5fa8d3` | Accents, CTAs |
| **Void** | `#0a0a0a` | Darkest surface |
| **Carbon** | `#1a1a1a` | Dark surface |
| **Smoke** | `#2a2a2a` | Elevated surface |
| **Stone** | `#4a4a4a` | Borders, dividers |
| **Cloud** | `#e5e5e5` | Light surface |
| **White** | `#ffffff` | Text on dark |

---

## Adding Components

1. Create component in `Sources/SaneUI/Components/`
2. Add SwiftUI preview
3. Document public API
4. Run `swift test`
5. Update consuming apps if needed
