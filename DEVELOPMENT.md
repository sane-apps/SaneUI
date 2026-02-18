# SaneUI Development Guide (SOP)

**Version 1.0** | Last updated: 2026-02-02

> **Shared UI library for all Sane Apps**

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

## 🚀 Quick Start

```bash
# Build
swift build

# Test
swift test

# Check which apps use this
rg -n "SaneUI" ~/SaneApps/apps/* || true
```

---

## The Rules (Adapted for Swift Package)

### #1: STAY IN YOUR LANE

All files stay in `/Users/sj/SaneApps/apps/Projects/SaneUI/`

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

## Project Structure

```
SaneUI/
├── Sources/SaneUI/
│   ├── Colors/          # Brand color definitions
│   ├── Typography/      # Font styles
│   ├── Components/      # Reusable UI components
│   └── Extensions/      # SwiftUI extensions
├── Tests/SaneUITests/   # Unit tests
└── Package.swift        # Package manifest
```

---

## Adding a New Component

1. **Create file** in `Sources/SaneUI/Components/`
2. **Add Preview** at bottom of file
3. **Document public API** with comments
4. **Add tests** in `Tests/SaneUITests/`
5. **Run** `swift test`
6. **Update** consuming apps if API changed

---

## Brand Guidelines Integration

SaneUI implements the [Brand Guidelines](../../meta/Brand/SaneApps-Brand-Guidelines.md):

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

**Before changing any public API**, check all consumers.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Build fails in consuming app | Check Package.swift path is correct |
| Color not showing | Verify color is `public` |
| Preview not working | Check `#if DEBUG` wrapper |
