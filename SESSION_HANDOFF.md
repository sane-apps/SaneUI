# SaneUI Session Handoff

Last updated: 2026-05-09

## Current Status

- 2026-05-08/09 shared SaneUI hardening is active in the working tree:
  - `SaneApplicationMover` is the shared move-to-Applications implementation for direct-download apps, with copy-then-relaunch behavior, destination verification, user Applications fallback, and loop prevention.
  - `SaneUpdateEligibility` and `SaneSparkleRow` make update controls unavailable outside `/Applications` or `~/Applications` instead of letting Sparkle fail later.
  - `SaneStandardMenu.addCoreUtilityItems` is the shared customer-critical utility menu contract for background apps: Settings, License, Check for Updates, About / Report a Bug, optional What's New, optional app utilities, then Quit.
  - `SaneFeedbackView` supports diagnostics-backed in-app bug reports with media attachments.
  - `SaneLoginItemToggle` centralizes launch-at-login UI.
  - `SanePermissionGuidanceView` centralizes permission explanation/recovery rows.
  - `SaneAppStorage` gives apps an app-owned storage helper so shared surfaces do not reach into protected user folders casually.
  - `SaneAboutLicenseCatalog` centralizes shared About/license payloads.
  - `KeychainService` continues to own license Keychain storage.
- Shared settings source-of-truth is no longer implicit component files only. `Sources/SaneUICatalog/SaneUICatalogApp.swift` is the standalone visual catalog for Foundations, Controls, Settings, License, About, permissions, and States.
- README, ARCHITECTURE, and DEVELOPMENT were refreshed on 2026-05-09 to describe the new shared surfaces and the actual `Sources/SaneUI/Components` layout.

## Latest Verification

- Mini `swift test` passed `95` tests for the current shared-surface set.
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

- Replace remaining app-local updater/settings clones with the shared catalog-backed SaneUI surfaces.
- Adopt shared settings/About/license/update surfaces in SaneVideo and SaneSync where guard scans still flag local implementations.
- Extend `SaneStandardMenu` coverage from label/order into update item enablement/help/state so menus do not repeat update eligibility logic app-by-app.
- Add broader SaneProcess source scanning for local `TabView` settings/About/license surfaces and permission API to Info.plist/privacy manifest coverage.
- Keep the catalog current whenever shared settings/About/license/update/permissions layout changes.
