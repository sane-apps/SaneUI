# SaneUI Session Handoff

Last updated: 2026-07-04

## 2026-07-10 Settings Rendering and Selection Visibility

- Replaced `SaneSettingsContainer`'s `NavigationSplitView` with a deterministic
  `HStack` sidebar/detail layout after SaneVideo's native Settings scene exposed
  a macOS 26 compositor failure: the accessibility tree contained every control,
  but the pixels showed only the gradient backgrounds.
- The shared sidebar now uses explicit accessible buttons and `ScrollViewReader`.
  It reveals the selected tab on first presentation and on real selection changes,
  without resetting a user's manual scroll position when selection is unchanged.
- Settings chrome uses a private pure-SwiftUI linear gradient, not the shared
  NSVisualEffectView-backed background, to avoid intermittent native Settings
  host compositing that could paint only the background over live controls.
- Verification: Mini `swift test` passed 119 tests before the visibility follow-up;
  rerun the full package suite after integrating this follow-up change.

## 2026-07-04 Direct Trial Hard Paywall

- Updated the shared direct-trial policy: paid SaneApps Mac apps now show the
  shared `LicenseGateView` after a 14-day trial expires instead of falling back
  to Basic.
- `LicenseGateView` now carries the Mr. Sane sustainability message, the
  aggregate 100K+/0.5% conversion stat, Buy Pro, Donate, Enter License, and
  Quit actions. Donation stays direct-download only so App Store/Setapp builds
  do not inherit external support links.
- SaneBar remains the open-source exception: its sponsor ask stays donation-only
  and must not gate app use.

## 2026-07-02 Signed Automation Keychain Bypass

- Fixed `KeychainService.shouldBypassKeychain` so explicit automation bypasses
  (`--sane-no-keychain` and `SANEAPPS_DISABLE_KEYCHAIN=1`) work in signed
  Release/Developer ID builds, not only DEBUG builds.
- This was required for SaneClip Glenn #994 Pro-mode proof: `sane_test.rb`
  correctly wrote `test-pro` into `com.saneclip.app`, but the signed app still
  used Keychain until SaneUI honored the no-keychain runtime flags.
- SaneClip verified this through the local monorepo SaneUI path during Mini
  proof; public SaneClip releases must pin the pushed SaneUI commit instead of
  shipping a local package reference.
- Verification: `swift test` passed 117 SaneUI tests; SaneClip Mini
  `./scripts/SaneMaster.rb verify --timeout 900 --no-grant-permissions` passed
  189 tests after adopting local SaneUI.

## 2026-06-22 Companion App Cross-Sell Cards

- Updated shared `WelcomeGateView` companion recommendations from plain text tiles to app-specific visual cards with the real bundled app icons, bright 13pt+ copy, stronger outlines, hover lift, and an explicit "Open" cue.
- Removed the temporary `SaneUICatalog` preview after visual QA so internal Basic/Pro/Setapp catalog controls do not remain part of the workflow.
- Verification: Mini `swift test` passed 115 tests.
- Visual receipt: `/Users/sj/Desktop/Screenshots/SaneUI/cross-sell-real-icons-onboarding-20260622-220726.png`
- Visual QA note: rejected earlier captures because one included internal catalog Basic/Pro/Setapp controls, another showed blank icon placeholders, and another used lower-contrast teal buttons. Final capture uses real app icons and the shared selected-control glass gradient for primary buttons.
- Related note: the unrelated SaneBar customer UI sweep failed because an onboarding welcome sheet covered License settings during the license-entry probe; failure screenshot saved at `/Users/sj/Desktop/Screenshots/SaneBar/customer-ui-license-entry-missing-20260622-210650.png`.

## 2026-06-22 14-Day Pro Trial Welcome Gate

- Historical note: this originally made Basic the automatic fallback after the
  trial, with expired trials showing "Keep Pro" plus a Basic continuation path.
  The July 4 hard-paywall policy supersedes that fallback for paid SaneApps Mac
  apps.
- Existing paid Pro users remain outside the trial downgrade path; this is copy/state behavior around trial onboarding and expiration.
- Visual receipt: `/Users/sj/SaneApps/infra/SaneProcess/outputs/final-review-2026-06-22/visual-audit.md`
- Verification: focused SaneUI render screenshot pass completed during final review; SaneBar Mini verify later passed after rendering app-local setup screenshots.

## 2026-05-25 Optional Pro Trial Support

- Added opt-in 30-day Pro trial support to `LicenseService` through `ProTrialConfiguration`. Trials are disabled by default, start only for direct-backend apps that explicitly opt in, and are ignored when force-free mode is active.
- Trial-aware license state now feeds the shared settings badge and welcome gate so apps can show "Pro Trial", days remaining, and a "Keep Pro" purchase CTA without inventing local license chrome.
- SaneHosts opts in with storage prefix `sanehosts.pro_trial` and a 30-day duration.
- Verification: local `swift test` passed `105` SaneUI tests. SaneHosts Mini `./scripts/SaneMaster.rb verify --timeout 1200` passed `97` tests and runtime proof logged `sanehosts.pro_trial_started`.

## 2026-05-18 License Key Paste Reliability

- SaneBar GitHub `#148` showed the shared license-entry sheet could ignore paste/type input when the visible key field did not become the active key target.
- `Sources/SaneUI/License/LicenseEntryView.swift` now auto-focuses the license key field on presentation and includes an explicit clipboard paste button (`saneui-license-paste`) that reads the system clipboard directly on macOS and UIKit platforms.
- Added SaneUI source guards in `Tests/SaneUITests/SaneUITests.swift` for the focus and paste fallback. SaneBar now pins SaneUI to commit `da41307 Improve license key paste handling`.
- Verification: Mini `swift test` passed `100` tests. `swiftformat --lint --trailing-commas never Sources/SaneUI/License/LicenseEntryView.swift` passed. Note: `Tests/SaneUITests/SaneUITests.swift` still has unrelated pre-existing local formatting/dirty changes outside the committed hunk.

## 2026-05-15 Reporting Regression Hardening

- Hardened `SaneFeedbackView` so selected media is clearly a local preparation step, not an automatic upload. When media is selected, the report sheet now stays open after GitHub launches, and packaging failures show a visible "Needs Attention" message instead of silently dropping the files.
- Replaced the misleading privacy line with: "Nothing is sent automatically. GitHub issues are public, so use email for sensitive logs or media."
- Added public-diagnostics redaction in `SaneDiagnosticReport.sanitizedForPublicDiagnostics(_:)` and run it across user description, logs, and settings summaries before GitHub markdown is generated. It redacts local paths, file URLs, emails, common token shapes, and secret-like key/value pairs.
- Documented the support-reporting contract in `DEVELOPMENT.md`.
- Verification:
  - Local `swift test` passed 98/98 tests.
  - Mini temp-copy verification passed `swift test --filter SaneFeedbackCopyTests` 4/4 and `swift test --filter DiagnosticsReportingTests` 4/4 against the exact local patch.

## 2026-05-15 Support Report Copy Fix

- Matthew Longbottom's SaneBar support thread exposed a misleading report-flow assumption: selected media was prepared in a local folder for GitHub, but the copy could be read as if diagnostics/media were automatically attached remotely.
- `SaneFeedbackCopy.subtitle` now says diagnostics are copied for GitHub and selected media is prepared locally.
- `SaneFeedbackCopy.mediaInstruction` now tells the customer to drag prepared files into the GitHub issue and to paste a file-sharing link for large videos.
- Verification: `swift test --filter SaneFeedbackCopyTests` passed 4/4 tests.

## Current Status

- 2026-05-08/09 shared SaneUI hardening is active in the working tree:
  - `SaneApplicationMover` is the shared move-to-Applications implementation for direct-download apps, with copy-then-relaunch behavior, destination verification, user Applications fallback, and loop prevention.
  - `SaneUpdateEligibility` makes update controls unavailable outside `/Applications` or `~/Applications` instead of letting Sparkle fail later; Sparkle settings rows stay app-local and channel-gated.
  - `SaneStandardMenu.addCoreUtilityItems` is the shared customer-critical utility menu contract for background apps: Settings, License, Check for Updates, About / Report a Bug, optional What's New, optional app utilities, then Quit.
  - `SaneFeedbackView` supports diagnostics-backed in-app bug reports with media attachments, explicit close/cancel escape paths, and an attachment package for selected media.
  - `SaneLoginItemToggle` centralizes launch-at-login UI.
  - `SanePermissionGuidanceView` centralizes permission explanation/recovery rows.
  - `SaneAppStorage` gives apps an app-owned storage helper so shared surfaces do not reach into protected user folders casually.
  - `SaneAboutLicenseCatalog` centralizes shared About/license payloads.
  - `KeychainService` continues to own license Keychain storage.
- Shared settings source-of-truth is no longer implicit component files only. `Sources/SaneUICatalog/SaneUICatalogApp.swift` is the standalone visual catalog for Foundations, Controls, Settings, License, About, permissions, and States.
- README, ARCHITECTURE, and DEVELOPMENT were refreshed on 2026-05-09 to describe the new shared surfaces and the actual `Sources/SaneUI/Components` layout.

## Latest Verification

- Mini `swift test` passed `96` tests for the current shared-surface set on 2026-05-09, including feedback media attachment and escape-path coverage.
- SaneProcess guard coverage passed after shared SaneUI updates:
  - `scripts/sanemaster/saneui_guard_test.rb`
  - `scripts/app_test_mode_test.rb`
- Earlier cross-app menu parity patches were verified on the Mini:
  - SaneBar: 1,164 tests
  - SaneClick: 103 tests
  - SaneClip: 154 tests
  - SaneSales: 74 tests
  - SaneHosts: 82 tests
- SaneUI itself currently has no open GitHub issues returned by `gh issue list`.

## Known Follow-Up

- Replace remaining app-local settings clones with shared catalog-backed SaneUI surfaces, but keep Sparkle updater controls app-local for channel hygiene.
- Adopt shared settings/About/license/update surfaces in SaneVideo and SaneSync where guard scans still flag local implementations.
- Extend `SaneStandardMenu` coverage from label/order into update item enablement/help/state so menus do not repeat update eligibility logic app-by-app.
- Add broader SaneProcess source scanning for local `TabView` settings/About/license surfaces and permission API to Info.plist/privacy manifest coverage.
- Keep the catalog current whenever shared settings/About/license/update/permissions layout changes.
## 2026-07-10 Native Settings Rendering Fix

- Real SaneVideo runtime screenshots on macOS 26 showed a blank Settings window even though the accessibility tree contained every sidebar row and detail control.
- The shared `SaneSettingsContainer` no longer uses `NavigationSplitView` in native `Settings {}` hosts. It now uses a deterministic scrollable button sidebar and explicit detail pane so the compositor paints the visible controls reliably.
- Selection bindings, selected accessibility traits, SaneUI chrome, and the shared settings-window paste behavior remain covered.
- Verification: full Mini `swift test` passed 119 tests across 27 suites; `git diff --check` passed. SaneVideo must pin the resulting SaneUI revision and repeat screenshot QA before release.

## 2026-07-10 Public About Destinations

- `SaneAboutView` now accepts optional typed primary/support action links so apps with private repositories can route customers to working public destinations without cloning shared About UI.
- SaneVideo uses this to label and route the actions to its public Website and Support pages while retaining the diagnostics-backed in-app bug reporter and shared license surface.
- Verification: full Mini `swift test` passed 120 tests across 27 suites; `git diff --check` passed.
