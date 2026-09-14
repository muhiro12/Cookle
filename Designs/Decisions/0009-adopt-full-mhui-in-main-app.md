# ADR 0009: Adopt Full MHUI in the Main App

- Status: Accepted
- Date: 2026-09-14
- Supersedes: Only the Cookle app presentation bullets of ADR 0008

## Context

Cookle 3.9 has shipped. The post-release presentation review compared the
existing Recipe Detail, a native List treatment, and a broader MHUI
composition with identical content, ordering, navigation, and actions.
The expanded composition was selected for Recipe Detail and establishes the
direction for broader adoption in the main app.

MHUI 1.18 supports both native List/Form chrome and composed reading screens.
Stally demonstrates the native-container route; Cookle's Recipe Detail
comparison supplies the evidence for the composed route. Neither route
requires changing the product's information architecture.

## Decision

- `Cookle` links the full `MHUI` product with the remote version requirement
  `1.18.0..<2.0.0` and applies `.mhTheme(.standard)` at its application root.
  It accesses existing MHDesign metrics through MHUI's re-export, without a
  separate direct MHDesign product dependency or metric-value changes.
- Recipe Detail uses `mhScreen`, nine `mhSection` groups, `MHGroupedRows`,
  adaptive ingredient `mhKeyValue` layout, and a vertical `MHActionGroup`.
  Cooking is primary and deletion is destructive. Existing facts, conditions,
  section and action order, handlers, navigation, and confirmations remain.
- Adopt MHUI broadly at app-owned screen boundaries. Choose composed reading
  surfaces or native List/Form chrome according to the screen's interaction
  needs. Native selection, swipe actions, reordering, fields, focus, and
  keyboard behavior remain reasons to retain native containers.
- Cookle owns screen composition, wording, accent assets, routes, state, and
  behavior. MHUI owns its theme and selected presentation primitives. Do not
  move domain behavior, generic helpers, or screen models into MHUI.
- Full-screen media, system pickers, camera, share sheets, alerts, and
  package-owned presentations may retain their native or owning presentation.
  Glass belongs to appropriate controls, not recipe text surfaces.
- `CookleLibrary`, `Watch`, and `Widgets` remain outside this adoption and gain
  no MHUI/MHDesign dependencies. App Intent implementations remain behavior
  adapters without presentation-package imports. Reused recipe sections
  default to native presentation for search results and Intent snippets.
- This decision does not change MHPlatform boundaries, Operations contracts,
  deployment support, persistence, or release policy. New features and
  diary-list information architecture are separate work.

## Rollout and Verification

The application root and expanded Recipe Detail establish the first slice.
The [main-app rollout](../Plans/mhui-app-rollout.md) records subsequent
screen choices, semantic commits, before/after evidence, and verification
gaps. Native lists and forms use container chrome; cooking and the photo
collection use composed layout; detached editors use input chrome.
Root linkage alone does not complete adoption, and implementation does not
replace the screen-level verification recorded there.

Repository checks require the actual Cookle MHUI product and Frameworks edges,
validate the remote minimum, and reject separate MHDesign links and excluded
surface imports or links. Negative checks use disposable copies.

Each affected screen needs an app build and targeted runtime evidence for
content, routes, actions, size classes, appearance, and accessibility. Existing
comparison captures establish the selected phone direction; they do not prove
production navigation, photo behavior, VoiceOver, or distribution readiness.
Package behavior changes require package verification and affected-consumer
checks. This adoption leaves the approved MHUI 1.18 package unchanged.

## Consequences

Recipe Detail delegates more layout and action styling to MHUI. Additional
insets and adaptive layout can increase wrapping and scroll length. The
selected comparison accepts that tradeoff while preserving the recipe data
and available operations. Native-container adoption remains a complete route
for screens with different interaction needs.

ADR 0008 remains authoritative for all unaffected package, library, adapter,
Operations, and test-posture boundaries.
