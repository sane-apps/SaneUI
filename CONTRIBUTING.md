# Contributing to SaneUI

Thanks for your interest in contributing to SaneUI, the shared UI component library for Sane Apps!

---

## What is SaneUI?

SaneUI is a Swift Package containing shared UI components, styles, and brand assets used across all Sane Apps (SaneBar, SaneClip, SaneVideo, SaneSync, SaneHosts).

**Part of the Sane Apps family** - See [saneapps.com](https://saneapps.com)

---

## Quick Start

```bash
# Clone the repo
git clone https://github.com/sane-apps/SaneUI.git
cd SaneUI

# Build and test
swift build
swift test
```

---

## Development Environment

### Requirements

- **macOS 14.0+**
- **Xcode 16+**
- **Swift 6.0+**

### Adding SaneUI to a Sane App

In the app's `Package.swift` or Xcode project:

```swift
.package(path: "../Projects/SaneUI")
```

---

## Project Structure

```
SaneUI/
├── Sources/SaneUI/
│   ├── Colors/          # Brand color definitions
│   ├── Typography/      # Font styles
│   ├── Components/      # Reusable UI components
│   └── Extensions/      # SwiftUI extensions
├── Tests/
└── Package.swift
```

---

## Brand Guidelines

SaneUI implements the [Sane Apps Brand Guidelines](../../meta/Brand/SaneApps-Brand-Guidelines.md):

### Colors
- **Navy**: `#1a2744` - Logo background, dark surfaces
- **Glowing Teal**: `#5fa8d3` - Accents, CTAs
- **Surface Colors**: Void, Carbon, Smoke, Stone, Cloud, White

### Typography
- **Primary**: SF Pro Display (system font)
- **Code**: SF Mono

### Philosophy
All components should embody:
- **Power**: User control, not extraction
- **Love**: Built to serve, not manipulate
- **Sound Mind**: Clear, calm design

---

## Coding Standards

### Swift
- **Swift 5.9+** features encouraged
- **@Observable** instead of @StateObject
- **Swift Testing** framework for tests

### Component Guidelines
- Keep components focused and reusable
- Document public APIs with comments
- Include previews for SwiftUI components
- Follow existing naming conventions

---

## Making Changes

### Before You Start

1. Check if the component already exists
2. Consider if it belongs in SaneUI (shared) or the specific app

### Pull Request Process

1. **Fork** the repository
2. **Create a branch** from `main`
3. **Make your changes** following the coding standards
4. **Run tests**: `swift test`
5. **Submit PR** with clear description

---

## Questions?

- Open an issue on GitHub
- See the [Sane Apps documentation](../../meta/)

<!-- SANEAPPS_AI_CONTRIB_START -->
## Become a Contributor (Even if You Don't Code)

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
