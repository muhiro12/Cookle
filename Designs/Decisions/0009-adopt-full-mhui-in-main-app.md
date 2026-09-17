# ADR 0009: Adopt Full MHUI in the Main App

- Status: Accepted
- Date: 2026-09-14
- Supersedes: Only the Cookle app presentation bullets of ADR 0008

The companion exclusion below describes this original rollout only.
[ADR 0010](0010-evaluate-mhui-for-companion-surfaces.md) evaluates those
surfaces independently for later adoption.

## Context

Cookle 3.9 has shipped. The post-release presentation review compared the
existing Recipe Detail, a native List treatment, and a broader MHUI
composition with identical content, ordering, navigation, and actions.
The expanded composition was selected for Recipe Detail and establishes the
direction for broader adoption in the main app.

MHUI 1.20 supports both native List/Form chrome and composed reading screens.
Stally demonstrates the native-container route; Cookle's Recipe Detail
comparison supplies the evidence for the composed route. Neither route
requires changing the product's information architecture.

## Decision

- `Cookle` links the full `MHUI` product with the remote version requirement
  `1.20.0..<2.0.0` and applies the standard Linen palette once at its
  application root.
  It accesses existing MHDesign metrics through MHUI's re-export, without a
  separate direct MHDesign product dependency or metric-value changes.
- Recipe Detail uses `mhScreen` with a leading photo and compact recipe facts,
  followed by cooking and diary actions. Ingredients, categories, and diaries
  use grouped surfaces; steps and notes use unframed reading sections.
  Dates and secondary actions form the quieter closing area. Cooking is
  primary and deletion is destructive. Existing facts, conditions, handlers,
  navigation, and confirmations remain; Edit stays in the native toolbar.
- Adopt MHUI broadly at app-owned screen boundaries. App-owned browsing and
  reading surfaces use composed MHUI hierarchy by default. Retain a native
  List or Form when the container supplies a concrete interaction benefit,
  such as selection semantics, swipe actions, reordering, fields, focus, or
  keyboard behavior. Native controls do not require a native container.
- Cookle owns screen composition, wording, accent assets, routes, state, and
  behavior. MHUI owns its theme and selected presentation primitives. Do not
  move domain behavior, generic helpers, or screen models into MHUI.
- Full-screen media, system pickers, camera, share sheets, alerts, and
  package-owned presentations may retain their native or owning presentation.
  Glass belongs to appropriate controls, not recipe text surfaces.
- `CookleLibrary`, `Watch`, and `Widgets` remain outside this adoption and gain
  no MHUI/MHDesign dependencies. App Intent implementations remain behavior
  adapters without presentation-package imports. Reused recipe sections
  default to native presentation for Intent snippets.
- This decision does not change MHPlatform boundaries, Operations contracts,
  deployment support, persistence, or release policy. New features and
  diary-list information architecture are separate work.

## Rollout and Verification

The dependency baseline advanced to MHUI 1.19 on 2026-09-15. Cookle inherits
its revised semantic palette, typography, surface borders, and heading
decoration removal through the standard components and theme. The app does
not use removed heading-cue APIs or override package-owned theme values.
The baseline advanced again to MHUI 1.20 on 2026-09-17. The update preserves
the established source contract while adding app-wide palette selection,
native-container ownership guidance, and explicit Liquid Glass opt-in for
floating actions. Cookle selects Linen to pair MHUI's warm neutral surfaces
with the app-owned orange accent, keeps native List/Form rows and sections
platform-owned, and relies
on the non-glass content-action default instead of disabling Glass across
complete recipe and cooking screens.
The subsequent composition refinement applies the SDK's visual hierarchy:
reading content gains emphasis through alignment and spacing, while surfaces
group related rows and action styles identify the next useful operation.

The application root and expanded Recipe Detail establish the first slice.
Recipe browsing, the Diary landing screen, and Search results subsequently
adopt the same composed screen, grouped-row, and surface vocabulary. Search
keeps the native searchable field and activation behavior.
The [main-app rollout](../Plans/mhui-app-rollout.md) records subsequent
screen choices, semantic commits, before/after evidence, and verification
gaps. Native lists and forms remain where their container behavior is useful;
cooking, browsing, Diary landing, Search results, and the photo collection use
composed layout; detached editors use input chrome.
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
checks. The original adoption left the approved MHUI 1.18 package unchanged.

## Consequences

Recipe Detail delegates shared spacing, typography, and action styling to
MHUI while Cookle chooses the reading order and where grouped surfaces help.
Unframed prose and compact facts reduce repeated card boundaries. Adaptive
layout can still increase wrapping and scroll length while preserving recipe
data and available operations. Main browsing surfaces now approach Recipe
Detail through the same visual language instead of weakening the detail
screen. Native-container adoption remains a complete route when a screen has
specific system interaction needs.

ADR 0008 remains authoritative for all unaffected package, library, adapter,
Operations, and test-posture boundaries.
