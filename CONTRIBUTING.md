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

- **macOS 15.0+** (Sequoia or later)
- **Xcode 16+**
- **Swift 5.9+**

### Adding SaneUI to a Sane App

In the app's `Package.swift` or Xcode project:

```swift
.package(path: "../../../infra/SaneUI")
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
