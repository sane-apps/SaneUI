# SaneUI Development Guide

**Last updated:** 2026-05-09

> Shared SwiftUI design system for the SaneApps product family.

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

## ⚠️ THIS HAS BURNED YOU

| Mistake | What Happened | Prevention |
|---------|---------------|------------|
| **Changed color without checking apps** | Broke visual consistency in 3 apps | Check all consuming apps before color changes |
| **Hardcoded values** | Same value in multiple places, got out of sync | Use semantic tokens, not raw hex |
| **Missing preview** | Component hard to test visually | Always add SwiftUI Preview |

---

## Quick Start

```bash
# Build
swift build

# Test
swift test

# Open the catalog app
swift run SaneUICatalog
```

---

## The Rules (Adapted for Swift Package)

### #1: STAY IN YOUR LANE

All files stay in `~/SaneApps/infra/SaneUI/`

### #2: VERIFY BEFORE YOU TRY

Check brand guidelines before adding/changing colors or typography:
`~/SaneApps/meta/Brand/SaneApps-Brand-Guidelines.md`

### #3: TWO STRIKES? INVESTIGATE

After 2 build failures → check Package.swift, verify imports

### #4: GREEN MEANS GO

`swift test` must pass before pushing

### #5: USE PROJECT TOOLS

```bash
swift build    # Not xcodebuild
swift test     # Not xcodebuild test
```

### #7: NO TEST? NO REST

New components need tests. No `#expect(true)`.

### #10: FIVE HUNDRED'S FINE, EIGHT'S THE LINE

Keep component files under 500 lines. Split by responsibility.

---

## Canonical Sources

Use the catalog and the shared docs before changing app-local settings UI:

- `README.md` for current package usage and shared-surface scope
- `ARCHITECTURE.md` for the catalog-first source-of-truth model
- `Sources/SaneUICatalog/SaneUICatalogApp.swift` for the live visual catalog

## Project Structure

```
SaneUI/
├── Sources/SaneUI/
│   ├── Components/          # Shared settings, menus, update, permissions, feedback
│   ├── License/             # Shared license views and Keychain storage
│   ├── Buttons.swift        # Shared button treatments
│   ├── Colors.swift         # Semantic colors
│   └── Backgrounds.swift    # Shared backgrounds and materials
├── Sources/SaneUICatalog/   # Live source-of-truth catalog app
├── Tests/SaneUITests/       # Unit tests
└── Package.swift            # Package manifest
```

---

## Adding a New Component

1. Extend the existing shared surface if one already exists.
2. If the component is shared settings/About/license/updater UI, update the catalog too.
3. Add focused tests in `Tests/SaneUITests/`.
4. Run `swift test`.
5. Verify at least one consuming app if the change alters shared behavior.

Shared surfaces that should stay centralized:

- settings shell and rows: `SaneSettingsContainer`, `CompactSection`, `CompactRow`
- customer utility menus: `SaneStandardMenu.addCoreUtilityItems`
- update/install recovery: `SaneSparkleRow`, `SaneUpdateEligibility`, `SaneApplicationMover`
- support surfaces: `SaneAboutView`, `SaneFeedbackView`, `SaneAboutLicenseCatalog`
- permissions and startup controls: `SanePermissionGuidanceView`, `SaneLoginItemToggle`
- storage and license persistence: `SaneAppStorage`, `KeychainService`

## App Store Surface Guardrails

Shared About/license/update UI is reused by direct, App Store, and Setapp builds. Before adding links or copy here, check the consuming channel:

- App Store builds must not expose GitHub Sponsors, crypto donation, external purchase, Sparkle update, or direct license-key unlock paths.
- Direct-download builds may show direct purchase/update surfaces when the app config explicitly enables them.
- Review shared About/license changes in `Sources/SaneUICatalog/SaneUICatalogApp.swift` and rerun the consuming app's `SaneMaster.rb appstore_preflight` before App Store submission.

---

## Brand Guidelines Integration

SaneUI implements the brand and shared-surface rules defined across the SaneApps docs:

### Colors
All colors come from the brand palette. Don't add arbitrary colors.

### Typography
SF Pro Display for headings, SF Pro for body. Use the defined scale.

### Philosophy
Components should embody:
- **Power**: User control, not extraction
- **Love**: Built to serve, not manipulate
- **Sound Mind**: Clear, calm design

---

## Self-Rating (MANDATORY)

After each task, rate yourself:

```
**Self-rating: 8/10**
✅ Added preview, ran tests
❌ Forgot to check consuming apps
```

| Score | Meaning |
|-------|---------|
| 9-10 | All guidelines followed |
| 7-8 | Minor miss |
| 5-6 | Notable gaps |
| 1-4 | Multiple violations |

---

## Consuming Apps

SaneUI is currently used by:

| App | Import Location |
|-----|-----------------|
| SaneBar | `Package.swift` |
| SaneClick | `project.yml` generated package dependency |
| SaneClip | `project.yml` generated package dependency |
| SaneHosts | `project.yml` generated package dependency |
| SaneSales | `project.yml` generated package dependency |
| SaneSync | `project.yml` generated package dependency |
| SaneVideo | `project.yml` generated package dependency |

**Before changing any public API**, check all consumers.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Build fails in consuming app | Check Package.swift path is correct |
| Color not showing | Verify color is `public` |
| Preview not working | Check `#if DEBUG` wrapper |
