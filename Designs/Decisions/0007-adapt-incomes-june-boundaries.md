# ADR 0007: Adapt Incomes June Boundaries to Cookle

- Status: Accepted
- Date: 2026-06-12

## Context

Incomes' June 2026 design cleanup clarified two reusable portfolio patterns:

- delivery surfaces should enter shared business use cases through stable
  library-facing boundaries
- local Apple verification should prefer XcodeBuildMCP where it provides the
  right evidence, while retained scripts cover static repository rules

Cookle already has the same core shape: `CookleLibrary` owns reusable recipe,
diary, tag, photo, route, storage, and mutation behavior, while `Cookle`,
`Widgets`, `Watch`, and App Intents adapt that behavior to Apple frameworks and
user interfaces.

The question is therefore not whether to copy Incomes' surface structure. The
decision is which Incomes intentions should be adopted directly, adapted to
Cookle's current service vocabulary, or left out.

## Decision

Cookle will align with the Incomes intent, not the Incomes naming surface.

### Adopt Directly

- Keep `CookleLibrary` as the behavioral source of truth.
- Keep app, widget, watch, and App Intent targets responsibility-thin.
- Keep App Intents as adapters rather than a parallel domain layer.
- Keep Apple-framework adapters, runtime assembly, notifications, review
  prompting, widget reloads, WatchConnectivity, and route intake out of the
  shared library.
- Keep repository-owned unit tests in `CookleLibrary/Tests`.
- Keep release UI smoke auditing separate from ordinary task verification.

### Adapt for Cookle

- Treat public `CookleLibrary` service APIs as Cookle's current
  business-use-case boundary.
- Keep app-side `*ActionService` types as workflow adapters that call shared
  services first, then perform platform side effects.
- Add new `*Operations` facades only when a new cross-surface use case would be
  clearer as a facade than as an extension of an existing service.
- If a view, widget, watch surface, or App Intent calls a low-level helper for
  business behavior, first add or extend a shared service API rather than
  copying the helper into the surface.
- If a static boundary check becomes necessary, make it Cookle-specific. Do
  not copy Incomes' finance-domain collaborator deny-list.
- Prefer XcodeBuildMCP for direct build, run, Simulator, log, screenshot, and
  UI snapshot evidence when a task needs that evidence outside the current
  shell gate.
- Keep the current shell verification contract until Cookle deliberately
  migrates to an MCP-first plus retained-rule contract.

### Do Not Adopt

- Do not bulk-rename existing `RecipeService`, `DiaryService`, `TagService`,
  `PhotoService`, or `DataResetService` APIs to `*Operations`.
- Do not introduce Incomes finance-specific operation families, yearly
  duplication flows, watch sync contracts, or navigation helpers.
- Do not remove `verify_task_completion.sh`, `verify_repository_state.sh`, CI
  run artifacts, or change-based build selection just to resemble Incomes.
- Do not add process-heavy public repository artifacts solely for portfolio
  symmetry.

## Consequences

- Cookle keeps its existing service vocabulary while making the boundary rule
  explicit for future work.
- Future cross-surface behavior can still adopt an `*Operations` suffix when it
  removes ambiguity, but the suffix is not required for already-clear service
  APIs.
- Verification can move toward XcodeBuildMCP without breaking the current
  repository contract or discarding useful `.build/ci/runs` evidence.
- Further code refactors should be driven by concrete Cookle drift, not by
  superficial parity with Incomes.
