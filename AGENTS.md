# AGENTS.md

Repository-specific agent contract for Cookle.

## Repository Rules

- Use English for branch names, code comments, documentation, and identifiers
  unless UI localization or legal content requires otherwise.
- Follow existing architecture and source style; keep changes small and
  repository-local.
- Markdown must follow
  <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md>.
- Swift code must comply with the repository SwiftLint configuration.

## Build and Test Entry Point

Agents MUST prefer the Xcode-native integration available in the current agent
environment for project discovery, active scheme and destination selection,
build, test, run, runtime logs, Preview rendering, live UI inspection, and
screenshots.

Before changing Xcode's active selection, discover the open projects, schemes,
and run destinations, identify `Cookle.xcodeproj`, and record the original
scheme and destination using the unambiguous identities returned by discovery.
Switch only to discovered values. End interaction sessions and stop runs
started solely for verification. After verification, restore the original
scheme first, rediscover its valid destinations, restore the original
destination, and confirm the final selection. Report any selection that cannot
be restored.

Treat library tests, surface builds, and runtime/UI evidence as separate
verification capabilities. Choose the smallest set that proves the current
change, and prefer stronger evidence when public APIs, wire contracts,
SwiftData schema, app lifecycle wiring, or visible UI behavior are affected.

- For shared-library logic, model, or test changes, use the available
  Xcode-native test capability with project `Cookle.xcodeproj`, scheme
  `CookleLibrary`, and a discovered iOS Simulator destination.
- For public `CookleLibrary` APIs, `*Operations`, shared contracts, SwiftData
  schema, or adapter-facing contracts, also build `Cookle.xcodeproj` with the
  `Cookle` scheme through the available Xcode-native integration.
- For app compile checks, use the Xcode-native build capability with project
  `Cookle.xcodeproj`, scheme `Cookle`, and a discovered iOS Simulator
  destination.
- For Widgets target changes, use the same build capability with the `Widgets`
  scheme and a discovered iOS Simulator destination.
- For Watch target changes, use the same build capability with the shared
  `Watch` scheme and a discovered watchOS Simulator destination. For Watch
  product linkage changes, also build `Cookle` to verify the embedding target.
  Paired-device delivery remains separate runtime evidence.
- For runtime or UI-sensitive changes, add a targeted Xcode-native run,
  runtime-log review, Preview rendering when appropriate, and live UI or
  screenshot evidence.

When Swift files are edited, agents should run:

``` sh
bash ci_scripts/tasks/format_swift.sh
```

Agents should also run the retained repository rule checks:

``` sh
bash ci_scripts/tasks/check_repository_rules.sh
```

`check_repository_rules.sh` runs SwiftLint plus repository-specific static
architecture checks that are not naturally covered by the available
Xcode-native integration.
SwiftLint is resolved from the `SimplyDanny/SwiftLintPlugins` package declared
in `Cookle.xcodeproj`, not from a separately installed `swiftlint` binary.
Xcode Cloud owns formal CI builds, tests, and archives.

Helper scripts may write disposable cache data under `.build/ci/shared/`.

## Release UI Smoke Audit

Release UI smoke auditing is separate from the standard verification entrypoint.
Keep it non-destructive by default: do not erase simulator data, reset
containers, or add UI test targets solely for the audit unless explicitly
requested.
