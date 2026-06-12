# ADR 0003: Platform Adapters Stay in App Target

- Date: 2026-03-23
- Status: Accepted

## Context

Cookle depends on notifications, WidgetKit reloads, review prompts, runtime
bootstrap wiring, and route intake. Those concerns are specific to Apple
frameworks and to the app target's runtime environment.

Moving them into `CookleLibrary` would make the shared library depend on
platform-only details and would weaken reuse across widgets and App Intents.

## Decision

Platform adapters stay in the app target.

Keep these concerns in `Cookle`:

- notification authorization and scheduling
- widget reload orchestration
- review flow wiring
- runtime bootstrap and route pipeline assembly
- App Intent dependency wiring

Keep these concerns in `CookleLibrary`:

- SwiftData models
- validation and mutation rules
- query and route helpers
- mutation effect hints

## Consequences

- `CookleLibrary` remains reusable and easier to reason about.
- App-owned side effects stay visible in one target instead of leaking through
  shared services.
- Cross-surface reuse happens through canonical library Operations APIs, not by
  sharing platform glue.
