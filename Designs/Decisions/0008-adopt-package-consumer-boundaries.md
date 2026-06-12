# ADR 0008: Adopt Current Package Consumer Boundaries

- Status: Accepted
- Date: 2026-06-12

## Context

MHPlatform 1.9 and MHUI 1.5 clarified consumer boundaries for the shared package
foundation used by Cookle and sibling apps.

MHPlatform now treats `MHPlatform` as the full-app composition umbrella,
`MHPlatformCore` as the shared-library default, and surface adapters as
consumers that should call app-owned shared APIs before adding direct platform
products.

MHUI now separates `MHDesign` metrics from the full `MHUI` styled surface and
explicitly keeps generic helpers and thin host-app presentation shortcuts
outside the package.

Cookle already has the matching app shape: app-owned adapters call shared
`*Operations` facades, repository-owned tests live in `CookleLibrary/Tests`, and
MCP-first verification is the Apple evidence surface.

## Decision

Cookle adopts the current package consumer boundaries without forcing full
package-surface parity.

- `Cookle` remains the full-app `MHPlatform` adopter.
- `CookleLibrary` remains on `MHPlatformCore` and stays off `MHPlatform`,
  `MHAppRuntime`, app-runtime split products, MHUI, and MHDesign.
- `Cookle` links `MHDesign` as a metrics-only dependency for shared spacing and
  radius values.
- `Cookle` does not link the full `MHUI` product until the app intentionally
  adopts package-owned styled primitives.
- `Widgets`, `Watch`, and App Intents call `CookleLibrary` APIs first and stay
  off app-runtime and presentation package umbrellas by default.
- Cookle does not keep a generic utility package dependency. Generic helpers
  and thin host-app presentation shortcuts are not migrated into MHUI.
- Repository static rules guard the package consumer boundary alongside the
  Operations and test-posture boundaries.

## Consequences

Cookle can consume newer MHPlatform and MHUI releases while preserving its own
domain and UI boundaries.

Shared package updates should be evaluated by responsibility:

- platform runtime and app composition concerns belong in the app target
- reusable business behavior belongs behind `CookleLibrary` Operations facades
- shared visual metrics can come from `MHDesign`
- Cookle-specific screen composition stays in Cookle views and screen models
- generic helpers stay app/shared-library-owned unless they become a stable
  platform-foundation contract

Future refactors should remove local glue only when the package now owns the
same durable responsibility. They should not replace Cookle domain adapters or
screen behavior solely because a sibling package exposes a similarly named API.
