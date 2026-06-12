# ADR 0007: Stage MCP-First and Operations Boundaries

- Status: Accepted
- Date: 2026-06-12

## Context

Incomes' June 2026 design cleanup clarified three reusable portfolio patterns:

- delivery surfaces should enter shared business use cases through stable
  `*Operations` library facades
- local Apple verification should be MCP-first, with retained scripts limited
  to static repository rules, SwiftLint/autofix, compatibility wrappers, or
  checks MCP does not naturally cover
- repository environment work, including static checks and test-target posture,
  should support the intended architecture rather than merely document it

Cookle already has the same core shape: `CookleLibrary` owns reusable recipe,
diary, tag, photo, route, storage, and mutation behavior, while `Cookle`,
`Widgets`, `Watch`, and App Intents adapt that behavior to Apple frameworks and
user interfaces.

The question is therefore not whether to copy Incomes' surface structure. The
decision is how Cookle should migrate toward the same intended end state while
preserving working verification and avoiding domain-irrelevant Incomes details.

## Decision

Cookle will adopt the Incomes direction in stages:

1. Make Apple build, test, run, Simulator, log, screenshot, and UI snapshot
   evidence MCP-first.
2. Move public cross-surface business use cases toward explicit
   `*Operations` facades in `CookleLibrary`.
3. Keep target adapters responsible for platform glue.
4. Retain only the shell scripts that support MCP-first development through
   SwiftLint/autofix, static repository rules, compatibility wrappers, or
   checks that MCP does not naturally cover.

### Direct Adoption

- Keep `CookleLibrary` as the behavioral source of truth.
- Keep app, widget, watch, and App Intent targets responsibility-thin.
- Keep App Intents as adapters rather than a parallel domain layer.
- Keep Apple-framework adapters, runtime assembly, notifications, review
  prompting, widget reloads, WatchConnectivity, and route intake out of the
  shared library.
- Keep repository-owned unit tests in `CookleLibrary/Tests`.
- Keep release UI smoke auditing separate from ordinary task verification.
- Use XcodeBuildMCP as the default local and agent evidence surface for Apple
  build, test, run, Simulator, runtime log, screenshot, and UI snapshot checks.

### Staged Adoption

- Treat current public `CookleLibrary` service APIs as migration candidates for
  `*Operations` facades, not as the final naming posture.
- Keep app-side `*ActionService` types as workflow adapters that call shared
  services first, then perform platform side effects.
- Add or migrate to `*Operations` facades by behavior boundary, not by
  mechanical rename. The facade should clarify the business use case that
  delivery surfaces call.
- If a view, widget, watch surface, or App Intent calls a low-level helper for
  business behavior, first add or migrate a shared Operations boundary rather
  than copying the helper into the surface.
- Introduce Cookle-specific static boundary checks as the Operations boundary
  becomes enforceable. Do not copy Incomes' finance-domain collaborator
  deny-list.
- Convert existing shell aggregate gates into compatibility wrappers around
  retained repository rules and, during migration, any build/test steps not yet
  covered by MCP defaults.
- Review test targets and scheme coverage as part of the migration. Keep
  durable tests in `CookleLibrary/Tests`; remove or avoid target-local test
  surfaces that would encourage business rules to live in adapters.

### Non-Goals

- Do not introduce Incomes finance-specific operation families, yearly
  duplication flows, watch sync contracts, or navigation helpers.
- Do not rename types without improving the boundary that delivery surfaces
  call.
- Do not delete compatibility wrappers before MCP and retained repository rules
  provide equivalent task-completion evidence.
- Do not add process-heavy public repository artifacts solely for portfolio
  symmetry.

## Consequences

- Cookle's current service vocabulary remains usable during migration, but it
  is not the final boundary target for cross-surface business use cases.
- Future cross-surface behavior should prefer `*Operations` facades, and
  existing services should be migrated when the facade clarifies surface usage
  or enables static enforcement.
- XcodeBuildMCP becomes the preferred evidence surface, while shell scripts
  shrink toward retained repository rules and migration compatibility.
- Further code refactors should be driven by concrete Cookle boundary drift,
  test posture, and verification-contract migration rather than superficial
  parity with Incomes.
