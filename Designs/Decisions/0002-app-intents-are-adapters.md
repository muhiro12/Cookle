# ADR 0002: App Intents Are Adapters

- Date: 2026-03-23
- Status: Accepted

## Context

Cookle exposes creation, update, delete, and navigation actions through App
Intents. Without a clear contract, those intents can drift into a parallel
domain layer by owning their own validation, mutation branching, or
success/failure semantics.

That drift would weaken the shared-library boundary and make App Intent
behavior differ from the main app.

## Decision

App Intents are adapters, not domain services.

App Intent files may:

- resolve entities and parameters
- call app adapters or shared query services
- convert errors into intent-facing failures
- return dialogs, values, and route-based destinations

App Intent files must not:

- become the only implementation of a user-facing mutation
- duplicate validation, search, or mutation branching from `CookleLibrary`
- return success results when blocking preflight or primary mutation failures
  occurred

The preferred flow is:

`App Intent parameter parsing -> app adapter/service -> CookleLibrary API -> intent result`

## Consequences

- App Intents stay thin and easier to review.
- Domain mutations remain reusable across the app and future system surfaces.
- Blocking failures keep consistent semantics between SwiftUI flows and App
  Intents.
