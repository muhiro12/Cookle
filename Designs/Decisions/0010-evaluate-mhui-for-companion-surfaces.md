# ADR 0010: Evaluate MHUI for Companion Surfaces

- Status: Accepted
- Date: 2026-09-14
- Supersedes: The blanket companion exclusion from the main-app rollout

## Context

CookleLibrary, Watch, and Widgets are evaluated individually for appropriate
MHUI adoption. The earlier main-app scope no longer excludes them from future
work. MHUI 1.18 includes watchOS support and compact layout metrics, but package
availability alone does not establish that its presentation fits every host.

## Decision

- Keep CookleLibrary presentation-free. It owns shared models, use cases, and
  transport values without view composition, so MHUI adds no current value.
- Keep Widgets on native SwiftUI and WidgetKit. Its family-specific content
  budgets, privacy annotations, and system-managed backgrounds have no current
  need for MHUI screen composition. Sharing a few spacing constants alone does
  not justify the dependency.
- Defer Watch adoption of the MHUI 1.18 standard surface. A cooking-screen
  comparison on watchOS 27 rendered the card white while native step text
  remained white. Repeated capture confirmed the unreadable result. Remove
  the candidate product link, theme injection, surface, and metric changes.
- Keep Watch-native scrolling, pager, typography, alerts, bordered controls,
  action handlers, and synchronization unchanged. Do not retain MHUI solely
  for the candidate's matching 8/12-point spacing and 44-point label metrics.
- Retain the shared Watch scheme and DEBUG Preview stores using synthetic
  snapshots with WatchConnectivity disabled. They provide a repeatable
  verification entrypoint without changing normal app launch behavior.

The MHUI 1.18 surface asset defines a white universal Any appearance and a
darker universal Dark appearance, with no Watch-specific variant. This is
consistent with the observed failure; a package-level cause has not been
proven on other watchOS versions. Apple documents that watchOS does not
support the system Dark Mode setting. A main-app dark capture therefore does
not prove that the same asset is suitable for Watch.

## Reconsideration and Boundaries

A later Watch adoption should first demonstrate readable semantic surfaces
and foregrounds in an isolated package or consumer fixture. Prefer correcting
shared platform behavior over forcing app-wide appearance or duplicating the
package palette locally. Then repeat the whole cooking-screen comparison,
small-Watch long-text checks, timer states, and accessibility-size capture.

When that evidence supports adoption, add the Watch MHUI product and actual
Frameworks link, apply the appropriate root theme and presentation components,
and update the project-link/import guards and current architecture documents
in the same semantic change. Keep Watch transport and Intents, shared models,
and other non-presentation code free of MHUI imports. Build both Watch and its
Cookle embedding target after changing linkage.

Current guards continue to allow full MHUI in Cookle only. This is the result
of the current surface evaluation, not a permanent exclusion of companion UI.
No shared package, deployment target, persistence, widget timeline, or runtime
transport change is part of this decision.

## Platform Basis

- [Designing for watchOS][watchos]: optimize for short, glanceable tasks.
- [Buttons][buttons]: retain familiar Watch controls and short labels.
- [Widgets][widgets]: preserve system backgrounds and limited content space.
- [Dark Mode][dark-mode]: watchOS does not support the system appearance mode.

[watchos]: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos
[buttons]: https://developer.apple.com/design/human-interface-guidelines/buttons
[widgets]: https://developer.apple.com/design/human-interface-guidelines/widgets
[dark-mode]: https://developer.apple.com/design/human-interface-guidelines/dark-mode
