# Session Handoff

Last updated: 2026-03-28

## Current Status

- Shared settings source-of-truth is no longer just implicit component files.
- `Sources/SaneUICatalog/SaneUICatalogApp.swift` now provides a standalone visual catalog for Foundations, Controls, Settings, License, About, and States.
- `Sources/SaneUI/Components/SaneSparkleRow.swift` now contains the shared updater row view, not just the frequency enum.
- README and ARCHITECTURE now describe SaneUI as the source of truth for shared settings/About/license/update surfaces, not just colors/backgrounds/icons.
- Catalog now forces regular macOS app activation so it can be launched and visually inspected as a normal window.

## Next Steps (Suggested)

- Replace the remaining app-local updater/settings clones in app repos with the shared catalog-backed SaneUI surfaces.
- Keep the catalog current whenever shared settings/About/license/update layout changes.
- Add more shared surfaces only when there is a real cross-app need, then document them in the catalog immediately.
