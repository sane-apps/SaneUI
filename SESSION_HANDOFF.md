## 2026-09-08 — Clip 2.3.24 paid-license loss (Glenn #1446)

- Symptom: Sparkle 2.3.24 dropped a paid Clip unlock to a fresh 14-day trial. Re-entering the key restored Pro. Screenshot: `~/Desktop/Screenshots/email1446-att346-Screenshot 2026-09-09 at 5.05.13 am.png`.
- Cause: 2.3.23 (SaneUI `10cd3ad`) stored the key in the login keychain. 2.3.24 (SaneUI `cefaf8c` / `8568997`) sets `kSecUseDataProtectionKeychain` for sandboxed Clip and only migrated when `accessGroup != nil`. Clip Sparkle has no access group, so the old key was invisible. Missing key + no sticky (sticky did not exist in 2.3.23) called `startProTrialIfNeeded` and minted a new trial.
- Shared fix (uncommitted): migrate whenever data-protection is in use, not only with an access group; if keychain read throws, apply sticky and do not start a new trial; persist sticky on the optimistic revalidate path.
- Tests: Mini `swift test --filter "License|Keychain|ProTrial"` 49 passed, including `unavailableKeychainDoesNotStartANewProTrial`.
- Do not ship Click 1.3.4 / Hosts 1.1.26 / Video 1.0.5 until they pin this SaneUI. Click live 1.3.3 is not sandboxed and already has sticky; Hosts already uses an access group; Video has no license gate. Clip 2.3.25 still needs this commit pushed and pinned.
- No email sent. Draft for #1446 is in the chat.

## 2026-09-07 11:49 ET — Settings contrast pass complete, source pushed

- SaneVideo main bb0c640132444026666f18b70dc0d82ae69bd883 and SaneUI main7286410171399b8cb0ba2ef7b253f267bd3d26d0 are published and synchronized on Air/Mini. Unrelated dirty work remains preserved; Air pre-sync stash retained.
- Required pre-push1233 app tests passed (workflow d7976f6a3cd9ef2506b74b01c8eaab30). Final shared152/29 suites pass. Exact final signed Release launched on Mini (workflow eb84383a1f7fcb4872a500644418c1e3), original com.sanevideo.app / teamM78L6FXD48 identity preserved.
- Final clean720x600 captures inspected: General11-46-12, Privacy11-47-03, About11-48-00. Bright white text, opaque dark cards, clear selection and semantic nav icons; no clipping/overlap, full About actions including pink Donate fit. Earlier eight-page content pass remains recorded below.
- Final General AX confirms automatic checksOff restored. Real Settings close removes its window while24545 remains alive; normal Quit15:48:54Z closes24545. Live log covered launch through quit: outputs/runtime-logs/20260907T154439Z-20260907-24220-xlhows/.
- Detailed receipt: apps/SaneVideo/outputs/portfolio-finish-20260907/settings-contrast-proof.json. Final images reside in that directory on Air; Mini originals captured by approved helper. Native resizing remains unchanged; failed attempts removed. No public app release/LS replacement; shared change adoption by other apps remains broader goal work.



## 2026-09-07 11:39 ET — Appearance scope final; resize attempt withdrawn

- Final shared7286410171399b8cb0ba2ef7b253f267bd3d26d0 is published and synced on Air.152/152 shared tests pass. Final patch retains opaque navy settings/cards, unboxed full-width navigation targets, white selected icon/marker, compact readable About header and existing native window sizing. Earlier153-test / native-resize-fix claims are superseded: the attempted feature and its new test were removed after failing live verification.
- Native Settings still reports AXSize settable:false. Both documented resize and actual edge drag failed to resize; drag changed x694 to614 and was deliberately restored to694. Scene contentMinSize did not resolve it. Both speculative changes were withdrawn. No640px/minimum-height verification or resizing fix is claimed.
- Complete actual About11-25-33 fits every action including Donate at720x600. New header is compact, all text and original actions preserved. License navigation status seal matches its real entitlement page. All eight settings content pages have inspected captures; complete About supplies final header and nav correction.
- Real automatic-checks Off->On revealed enabled frequency picker (11-35-46 capture). On->Off restored owner value and readable Daily text. Settings close succeeded while18407 stayed alive; normal Quit ended18407 and its live log. No media/credential mutation, permission prompt or TCC reset.
- Video bb0c640132444026666f18b70dc0d82ae69bd883 committed six scoped native/pin files. Required pre-push full verify is running (contrast-push.log). Exact final source binary, final concise visual receipt and Air main FF remain pending. Partial proof: apps/SaneVideo/outputs/portfolio-finish-20260907/settings-contrast-proof.json.
- No public app release or LS replacement. Broader portfolio goal remains active.

## 2026-09-07 11:23 ET — Final About / window follow-up active

- Current shared source b595a2a8c5a7e58e5357b930895f23609664a8d5 published main and FF-synced on Air. Full153/153 tests pass in infra/SaneUI/outputs/contrast-20260907/complete-tests.log. No native public release.
- e370a4d actual Video runtime (PID8867, identity1788793694553837) passed the prior failed row-whitespace click:850,396 selected Export. Full160pt sidebar AX targets restored. Eight settings pages were inspected in actual720x600 screenshots; About needed a42px scroll to reveal Donate (top11-16-08 and bottom11-17-11 are failure evidence for normal-size fit, not complete clearance).
- Compact About header now puts the existing icon beside the identity/trust text, preserving all copy/actions. License navigation icon restored to the access-status seal after actual page inspection; it is an entitlement page, not the legal document viewer.
- Native resize command refused without mutation and actual bottom-right drag left720x600 unchanged. No prompt visible (11-19-23 and11-20-50 screenshots). New real NSWindow regression failed original shared helper (no resizable flag), then passed fix. Shared configure now reuses saneApplySettingsChrome to enable resizing and keep640x400/960x760 bounds plus close button.
- Apple official WindowResizability docs checked2026-09-07: Settings defaults to contentSize; native bounds alone do not repair a fixed style mask. No extra scene modifier guessed. Normal Quit ended8867 and original live log at11:22 ET.
- Final b595a2a Video rebuild active: apps/SaneVideo/outputs/portfolio-finish-20260907/contrast-complete-launch.log. Final compact About, real resize/min-width/scroll, automatic-checks on/off restore, normal Settings close, source commit and complete consumer proof remain pending. Do not claim all-app or release clearance.

## 2026-09-07 11:07 ET — Contrast source verified, final runtime pending

- SaneUI6f25ef0 published:152/152 package tests pass. New native-render regression keeps the card unchanged over black/white backdrops and white text contrast >=7:1. Original Section source fails the same regression (4 assertions, contrast1.19:1 in isolated bright-backdrop rendering); source was restored afterward. Tests: infra/SaneUI/outputs/contrast-20260907/{final-tests,contrast-test,old-section-negative}.log.
- Actual Video rebuilt against6f25ef0: General11-02-38-w3622 and Privacy11-04-49-w3622 are clean inspected720x600 images in apps/SaneVideo/outputs/portfolio-finish-20260907. Strong navy cards, clear white text, complete Privacy copy/actions, unboxed sidebar. General update frequency remains readable when automatic checks are off; updates precede rare cache repair.
- Real empty-space click at850,396 in Export's row left Privacy selected: removing the fill shrank the native hit area. Follow-up e370a4dc5554c7cb6d97361cc912af9cc66b8c5f adds native contentShape(Rectangle); focused shared3/3 pass. Both source commits published main. Final actual row-whitespace regression after rebuild is pending.
- Video PID6273 quit normally; runtime20260907T150200Z-20260907-5991-gktpz0 was ready before launch, remained attached through the checks, and ended on normal quit. Final e370a4d consumer build is active: contrast-final-launch.log.
- Peekaboo AX-only snapshots omit exact-window identity; background snapshot click rejected and title lookup failed although window list exposes the Settings window. Stopped retries, read installed tool help/inventory, used supported foreground clicks at freshly observed AX bounds with immediate selected-state readback. No new permission/TCC reset. Saved failure screenshot11-05-52-w3622; no app dialog/prompt present.

## 2026-09-07 — Owner settings contrast correction active

- Owner rejects the current settings appearance as washed out/cluttered. Earlier clipping-only visual passes do not mean design acceptance.
- Fresh actual Mini SaneVideo 720x600 screenshot: apps/SaneVideo/outputs/portfolio-finish-20260907/codex-shot-2026-09-07_10-55-44-w3562.png (controller copy). It shows glossy dark cards, animated mesh behind controls and filled unselected navigation rows. Signed PID4243 quit normally after capture.
- Candidate shared settings uses opaque navy canvas/cards, transparent unselected rows, white selected icon/marker, fixed180pt sidebar and wrapping navigation labels. Existing components only. Source AGENTS glass-first guidance superseded by explicit owner correction.
- Apple primary references reviewed 2026-09-07, TTL30d: https://developer.apple.com/design/human-interface-guidelines/materials and https://developer.apple.com/videos/play/wwdc2025/219/ place Liquid Glass in controls/navigation above content. Decision: simple stable settings content surfaces; no animated decoration behind text.
- Shared test run compiled;151 tests passed, new render check sampled the header gap rather than the card (4 assertions), corrected to card y70. Focused rerun pending; no current green or visual-after claim. Video shared dependency pin/rebuild pending.
- Air SaneVideo safely fast-forwarded to published5f17235f50dcc80207de75a6957a1740b2c2d19c; restored prior dirt with retained stash portfolio-video-air-before-main-sync-20260907. Handoff-only merge conflicts resolved by retaining upstream sections, no unique Air text discarded. Prior pre-push1233 passed, workflow7344d04b430e1e91ef0c5ed567b38528. Source push is not public release.

# SaneUI Session Handoff

## 2026-09-06 21:10 ET consumer verification

- Published shared60176f3 now has actual native settings review in Clip760x532 and Video720x600. Clip's full Per-app paste mode label wraps above controls; Video Privacy & AI fits completely. Shared suite152/152 and the old-source negative layout control remain the regression evidence.
- Current consumer image hashes/actions/limits live in SaneProcess outputs/portfolio-review-20260906/{clip-settings-visual,video-runtime-20260906}/settings-visual-verification.json. Both apps quit normally after continuously logged reviews. This is settings coverage, not complete apps/releases.
- Hosts now source-pins60176f3 across its package and lockfiles on both hosts; package125/125 passes. Signed app build and actual native review are pending. Other consumer upgrades remain in the SaneProcess active queue.

## 2026-09-06 20:38 ET Clip settings review and Video rebuild

- Clip settings evidence is now saved as clip-settings-visual/settings-visual-verification.json under this portfolio output directory on both hosts. Eighteen inspected image entries include complete Shortcuts/Sync scroll coverage, Storage, paid License, About with both pink Donate hearts, General sections and Snippet draft/empty-search states. Scope remains settings visual review and the actual recorded safe actions, not all app actions or release clearance.
- Actual Settings close button removed all windows while Clip remained running. Separate normal Quit ended PID47588 and its original runtime capture at2026-09-07T00:35:48.316900Z, stop_reason app_exited. No Clip test surface remains active.
- SettingsColorTests stale green-text assertion updated to white permission text; excluded-app colored status icon policy retained. Mini canonical focused verify passed3/3, workflowedcb0a77f963be796d42f3f01073d69c. These are source-policy assertions, not behavioral visual proof. Continuous test capture ready00:35:48.846267Z survived through explicit stop00:36:30.256120Z. Existing fixture runner now rejects unhealthy final log state. Source/test hashes match Air and Mini; diff --check passes.
- Video shared60176f3 rebuild is in progress via canonical GUI launch. It detected the newer Package.resolved and correctly rejected the old binary. Log video-settings-layout-patches/adaptive-shared-launch.log, status adjacent. New runtime and current Privacy & AI inspection pending; prior verified screenshots remain historical.
- No public app release, LS upload/removal, new OS grant, TCC reset, or credential change in this phase. The portfolio goal remains incomplete.

## 2026-09-06 20:23 ET active verification

- SaneClip signed Release 2.3.24/2324 now runs shared SaneUI 60176f3, PID 47588, workflow 465a6551b519a8b616ae64178e180b63. Continuous log was ready 23:58:42.258539Z before launch 23:58:42.640216Z: apps/SaneClip/outputs/runtime-logs/20260906T235842Z-20260906-47092-3mv5qc/live.log; bounded deadline 00:58:42Z. This supersedes earlier pending-build entries.
- Current native proof under infra/SaneProcess/outputs/portfolio-review-20260906/clip-settings-visual/: 19-45-51 full Per-app paste mode after shared adaptive layout; 20-03-19 real search p gives No Results and bottom-aligned 0 of 3 snippets; clear button restores list. 20-10-23 filled draft has enabled Save; 20-12-08 bottom scroll exposes complete live Preview. Actual Cancel removed sheet and preserved three saved snippets. Save was not clicked. 20-15-13 confirms list bottom reachable; 20-17-12 confirms current Shortcuts top. All named images inspected. Snippet list uses normal scrolling with sticky category header; upper offscreen row is not a full-row screenshot. Further tab checks are active.
- SaneClip SnippetsSettingsView now has white Search label, wrapped instructions, full-height empty results, filtered count, shared editor buttons/background and 520pt minimum. General Granted status is white. Scoped source/pins synchronized with backups; unrelated owner changes preserved. No public Clip release.
- Peekaboo 4.3.1 installed on Mini and Air from official openclaw/tap. Mini retains prior signing team and observed grants; Air old unmanaged 3.4.0 binary retained in portfolio output before install. Air GUI/permissions were not exercised. Dependency baseline now preserves qualified tap names; Mini 31 tests pass, both host checks PASS. No TCC resets or permission requests. Manual Mini helper PID 51635 stopped; auto helper has bounded idle exit.
- SaneCite exact prior Worker/parser pair remains the last verified live state (19:27 entry); newer release remains unshipped. Paired recovery tool/workflow/tests are still unpublished candidate changes. Video is source-pinned 60176f3 but has not rebuilt since prior verified 5931685 run.
- Portfolio goal remains active. Three delegated agents stopped on account usage limits; continue root work without retrying delegation to bypass limits. All-app, release, full action coverage and complete Air/Mini parity remain unproven.

## 2026-09-06 19:42 ET active shared layout correction

- Shared SaneUI60176f30007e0f931195785aa769e4ef5172f7ee is published and synchronized to Air. CompactRow uses native ViewThatFits: full label beside controls when space permits, label above controls when crowded. CompactToggle labels wrap. Native400pt-vs700pt layout regression passes fixed source and fails old source; complete152tests/29suites pass. Two unchanged onboarding-copy/donation assertions were stale and updated; the former source assertion banning vertical wrapping was superseded by the native regression.
- Actual Clip760x532 General screenshot19:28:26 exposed truncated Per-app paste mode, motivating shared root repair. General sections at scroll0.43,0.65,0.85,1 were inspected; no security/history settings changed. Source status text is now white. Clip search now uses a visible white Search label because native placeholder ignored explicit white prompt. Snippet Add sheet was opened, scrolled to bottom and Cancel clicked; zero sheets afterward, no saved snippet changes. Editor shared style,520pt minimum and scroll indicators prepared for verification.
- Clip old PID24822/log3c0df2a3062011b78d2e3f35b61c488d ended normally23:40:45.432Z. New signed Release launch is building via canonical wrapper, log file infra/SaneProcess/outputs/portfolio-review-20260906/clip-settings-visual/adaptive-release-launch.log. Actual new UI proof pending; no public Clip2.3.24 release.
- Clip/Video source pins now60176f3 on both machines. Video has not rebuilt after its verified5931685 settings run; no claim of current601 runtime. Air per-file before backups and hashes in clip-settings-visual/air-adaptive-sync.json; unrelated metadata preserved.

## 2026-09-06 shared license styling follow-up

- Parent saw green Licensed text and a plain Donate control in actual Video settings17:34:35. Shared LicenseSettingsView now keeps badge text white and reuses SaneStickyDonateButton for filled pink heart/white label. Published5931685baa3d8c7aa9df3608c5234d45bfb769ec after native Swift package compile and2 existing settings-contract checks passed. No new API, dependency or entitlement behavior. Removed an existing unused optional binding warning. Native consumer screenshot/action proof remains pending.
- Air fast-forward preserved unrelated dirty handoff; current source matches Mini. Video three pins updated from0f04 to5931685 with exact Air/Mini hashes; canonical Release launch is rebuilding. Other app consumers have not yet adopted this style revision. Receipts: infra/SaneProcess/outputs/portfolio-review-20260906/license-entry-feedback/license-style*.


Last updated: 2026-08-13

## 2026-08-13 Note: dirty About test is not part of the license-gate fix

- Unrelated local dirty work: `SaneAboutView.swift` plus test
  `bugReporterFallbackUsesIssuesNotSupportAction`.
- That test uses `#filePath` and looks under `Tests/Sources/...`, so
  `swift test` fails with file-not-found. It is not caused by the
  closable license-gate change.
- Leave it uncommitted. Fix the test path (use `saneUIPackageRootURL()`)
  when that About change is finished. Do not mix it into the license-gate
  commit.

## 2026-08-13 Expired-trial gate is closable

- Owner: sell, do not trap. A leftover Debug SaneVideo from Mini nightly
  `verify` showed the old locked paywall and the close button did nothing.
- `LicenseGateView` no longer removes `.closable` and no longer terminates
  the app if the gate disappears unlicensed.
- **Not now** calls `LicenseService.continueWithoutPurchase()` (session-only).
  Apps show the gate with `shouldShowExpiredTrialGate`. Pro feature guards
  still use `isPro`.
- Quit remains an explicit leave. Buy / Enter License stay first.
- Wired: SaneVideo, SaneClick, SaneClip, SaneHosts, SaneSales, SaneSync.

## 2026-07-27 Neutral License and Purchase Surfaces

- Shared license, purchase, onboarding, upsell, and catalog surfaces now use
  neutral trial, purchase, and licensed wording instead of customer-visible tiers.
- The direct SaneClick fallback matches its live one-time price at `$14.99`.
- Direct Everything Bundle matching now uses an explicit five-app allowlist;
  its independent regression was committed separately as `656e1db`.
- Focused license, trial, neutral-copy, and product-matching verification passed
  44 tests across four suites on the Mini.
- Full Mini `nice -n 10 swift test` passed 134 tests across 28 suites.
- The unrelated heading-layout guidance in `AGENTS.md` and `README.md` remains
  uncommitted and was not included in either licensing commit.

## 2026-07-27 Neutral Direct Trial Onboarding

- Direct-download onboarding now presents one 14-day trial followed by a
  one-time purchase. It no longer shows Basic/Pro plan cards or Pro wording on
  the direct channel.
- App Store and Setapp onboarding branches remain unchanged.
- Focused neutral-copy/channel tests passed 16/16. Full Mini `swift test`
  passed 132 tests across 28 suites.
- The second setup screen now explains the walkthrough in positive language
  instead of scolding customers not to skip it.
- The direct-trial summary shows four key benefits so the 700x520 shared frame
  stays unclipped, and its final action says `Continue Trial`.
- The follow-up focused run passed 16/16 tests; full Mini `swift test` again
  passed 132 tests across 28 suites.
- The change is limited to `WelcomeGateView.swift` and its existing test file.
  Unrelated dirty licensing/product-matching work remains uncommitted and
  untouched.

## 2026-07-11 Settings Grid Alignment

- `CompactSection` now expands both its content card and outer section to the
  full available grid column. This removes intrinsic-content card widths that
  made adjacent Settings sections visibly asymmetric.
- Section header/card rhythm now uses a consistent 7-point gap and aligned
  horizontal insets.
- Added a non-tautological render test that draws a short-content section in a
  400-point column and samples the far edge to prove the real glass card fills
  the column. Full SaneUI verification passes 124 tests across 27 suites.

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

## 2026-08-03 — Settings frost + type restored (owner screenshot)

**What went wrong:** Jul 10 `9f21f36` / `bb8a298` killed living mesh/vibrancy in native Settings to dodge a macOS 26 NSVisualEffectView blank-window bug. A later attempt then painted `navy.opacity(0.55)` *on top of* `glassEffect`, which flattened every CompactSection across every app. Type floor drifted to 13pt / gray helper copy in places.

**Fix now:**
- Liquid glass rows: no dense navy overlay on macOS 26; light wash only on legacy blur.
- `SaneTypography` 14pt bright white floor; license/onboarding helpers bumped 13→14.
- Settings host keeps mesh with `useSystemVibrancy: false` (still avoids the Jul 10 compositor bug) so glass has life underneath.
- Apps pinning remote SaneUI must rebuild against this revision — SaneBar Package.resolved still points at GitHub.

**Verify:** `swift test` on Mini; SaneUICatalog + SaneBar Control settings screenshots.


## 2026-09-06 pink Donate dependency publication

- Shared SaneUI main published and verified at `7f425682151792572f0cd7b638ffaad2ec5691ab`: only AGENTS pink-heart policy, SaneStickyDonateButton pink icon, and donation-only LicenseSettingsView pink icon.
- Mini first fast-forwarded569922a to existing upstream3850741. Ten pre-existing dirty files exactly matched upstream; their bytes are retained in private custody and named stash9aceeab8dc402ca27a70e36948decc6b7a5857d7. No duplicate hunks reapplied.
- Isolated3850741 plus the three approved files passed SaneUI library build (29.53s); no catalog launch or app build. Package test suite and customer visual proof were not run by this dependency lane.
- Video and Sales now pin the exact published commit in project.yml, generated project and Package.resolved. Native Mini resolve-only commands passed; only saneui dependency state changed.
- Sales adds the localized moreAppsButtonTitle argument required by upstream3850741. XcodeGen preserved entitlement bytes; its existing target-list ordering changed without adding/removing targets.
- Air shared SaneUI fast-forward and seven consumer-file scoped patch are hash-verified; existing handoff and unrelated source were preserved. Consumer edits remain uncommitted; parent owns app build, runtime/visual proof and release.
- Receipts: `~/SaneApps/infra/SaneProcess/outputs/portfolio-review-20260906/donate-heart-patches/`, including shared/consumer custody manifests, upstream build, resolution logs and exact patches.

## 2026-09-06 — Active-trial license activation feedback (regressions verified; unpublished)

- Confirmed current published 7f42568 LicenseEntryView observes isPro, which is already true during a trial; successful paid activation therefore misses its visible success and delayed dismissal. Existing expired-trial activation uses false-to-true and is distinct.
- Traced both LicenseSettingsServiceProtocol implementations (shared service and retired SaneBar adapter): actual paid access excludes isProTrialActive. Changed only the observer to existing `isPro && !isProTrialActive`, without adding protocol API or consumer pin changes.
- Added four hosted fake-service regressions in existing SaneLicenseServiceSetappGateTests.swift: active-trial purchase, expired purchase, starting-trial negative, existing Setapp negative. They observe the real hosted view mount and delayed close callback; no real keys/network/payments. Rendered success text remains a separate app visual acceptance check.
- First Mini run compiled successfully (23.77s), then 4 tests failed 7 text-lookup assertions; paid close callbacks passed. Apple NSHostingView returns arbitrary accessibility children, so requiring full NSAccessibilityProtocol on every node was unsupported. That test assumption was removed after source/API review; the revised hosted mount/close timing tests subsequently passed (receipts below). No visual or public-release claim. Backup and hashes: SaneProcess outputs/portfolio-review-20260906/license-entry-feedback/.
- Primary Apple API checked 2026-09-06: https://developer.apple.com/documentation/appkit/nsaccessibilityprotocol. In-process hosted view inspection is test evidence, not customer app payment acceptance.

- First run receipt: SaneProcess outputs/portfolio-review-20260906/license-entry-feedback/hosted-20260906T192019Z.log; SaneUI outputs/runtime-logs/20260906T192019Z-20260906-45464-frwx80/receipt.json stopped19:20:58Z. Immediate canonical screenshot15:21:40 inspected: clean Finder desktop, no prompt. First AX test source retained in custody. Original-observer package is isolated under the same evidence directory for a controlled regression test; production source is not reverted.

### Verified hosted regression and original-source control

- Fixed working tree: canonical package `swift test --filter LicenseEntryPurchaseFeedbackTests`, Mini only, passed 4/4 in7.091s after2.26s build. Log: SaneProcess outputs/portfolio-review-20260906/license-entry-feedback/hosted-20260906T193256Z.log. Runtime receipt: SaneUI outputs/runtime-logs/20260906T193256Z-20260906-48914-4ob5yx/receipt.json; ready19:32:57.100939Z, stopped19:33:08.764703Z.
- Controlled original observer: same52-file package snapshot and identical tests, only LicenseEntryView replaced with byte-exact original. It failed exactly active-trial paid dismissal and trial-start false dismissal; expired purchase and existing Setapp controls passed. Expected exit1, four tests/8.479s. Log: same evidence directory/original-observer-20260906T193342Z.log. Capture under original-observer-package/outputs/runtime-logs/20260906T193342Z-20260906-49456-dl94ns/receipt.json; ready19:33:42.137708Z, stopped19:34:16.735601Z.
- Both runs used all four no-prompt flags,300s process bounds and360s prelaunch native logging. No real keys, network activation, or payment. Test/helper processes absent; parent test slot returned. Canonical Mini desktop screenshot15:34:51 inspected: clear Finder desktop, no prompt or app. Air copy: SaneProcess outputs/portfolio-review-20260906/license-entry-regression-desktop.png.
- This proves the hosted SwiftUI observer, real delayed close callback and negative controls. Customer app paid action, actual Activate button and visible success text still need parent runtime/visual proof. No shared publication, consumer pin changes, or release in this lane.
- Operational memory fix-status receipt: d0ae9dfd-b4d8-43cf-9646-2779742bd1ba, revision1249, supersedes pending bug ef6c65d7-3d05-4b5f-ad23-91510c701b70. Source/tests patch and before/final hashes live in license-entry-feedback/.

### Shared dependency publication and consumer scope (2026-09-06)

- Parent reviewed and authorized publishing exactly LicenseEntryView.swift plus SaneLicenseServiceSetappGateTests.swift. Remote main matched7f425682 before action; empty index, two file hashes and full patch SHA256 matched reviewed custody. Commit0f04e7536ca69ef684ef6835034d4916ccdbfd84 was pushed and remote main independently re-read at that commit. No unrelated files staged. Mini handoff/.claude dirt preserved.
- Air SaneUI fast-forwarded to the same exact commit, preserving prior handoff bytes by hash. This publishes a dependency only; no app release is claimed.
- Video advanced only project.yml, generated pbx SaneUI revision and Package.resolved from7f42568 to0f04e75. Mini native resolve-only succeeded19:40:27Z; other dependency states unchanged. Air three-file patch applied only after exact before hashes matched and verified all after hashes equal Mini. Parent owns Video build/runtime/release.
- Sales project.yml/pbx revisions prepared0f04; package lock still7f42568 pending the next approved resolve-only slot. Do not call its repin complete yet. No Sales source changes.
- Clip parent-approved three-file repin from8568997 to0f04 prepared, no resolve/build/test yet. Same exact source substitutions only; preserve all earlier license/window/AI/docs changes. Nearest app regressions: LicenseGateWindowTests.expiredGateCanCloseWithoutUnlocking plus four NonBlockingKeychainServiceTests. Actual paid cached recognition still requires normal signed customer runtime; these fixtures do not replace it.
- Prior Clip verify f93a43db1880d25bdb320ecf2dbe133e ran251tests, with gate tests passing and only two website-copy tests failing: publicBundleCopyIsConsistentAndVerifiable (literal bundle copy) and publicReleaseLinksAndMetadataUseProjectMarketingVersion (four assertions require candidate2.3.24 in public2.3.23 docs). These are independent of the dependency/gate change; never make unshipped public links just to satisfy them. Receipt Clip outputs/verify/20260906T064155.435257Z-24774-0be76a9d/01-test.log.
- Older-pin source compatibility reviewed: Clip/Click/Hosts call default SaneAboutView Labels, so added required moreAppsButtonTitle affects no custom label caller there. Donation parameters default nil and those licensed apps do not opt in. The repin also brings upstream settings/About sizing, rows/badges and sticky cached entitlement behavior; it requires relevant visual/cache proof, not blind latest. Clip and Click use embedded settings; Hosts takes shared720x600 ideal and960x760 maximum sizing.
- Click remains387e291 (three project/lock files proposed); Hosts remains387e291 (SaneHostsPackage/Package.swift and existing project/workspace locks proposed). Deferred until Clip. Sync stays8568997: it consumes shared Gate/Welcome, not LicenseEntryView, and retirement/whole-product safety questions remain; no blanket repin authorized.
