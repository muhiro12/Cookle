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

Agents MUST prefer XcodeBuildMCP for Apple build, test, run, Simulator,
runtime log, screenshot, and UI snapshot verification.

Before the first XcodeBuildMCP build, test, or run call in a session, run
XcodeBuildMCP `session_show_defaults`. If defaults do not point at this
repository, set them for the current session before continuing.

Treat library tests, surface builds, and runtime/UI evidence as separate
verification capabilities. Choose the smallest set that proves the current
change, and prefer stronger evidence when public APIs, wire contracts,
SwiftData schema, app lifecycle wiring, or visible UI behavior are affected.

- For shared-library logic, model, or test changes, use XcodeBuildMCP
  `test_sim` with the `CookleLibrary` scheme.
- For public `CookleLibrary` APIs, `*Operations`, shared contracts, SwiftData
  schema, or adapter-facing contracts, also use XcodeBuildMCP `build_sim` with
  the `Cookle` scheme.
- For app compile checks, use XcodeBuildMCP `build_sim` with the `Cookle`
  scheme.
- For Widgets target changes, use XcodeBuildMCP `build_sim` with the `Widgets`
  scheme.
- The repository currently has a Watch target but no shared Watch scheme; if
  Watch-specific code changes, report that verification gap unless a concrete
  Watch scheme is added or selected.
- For runtime or UI-sensitive changes, use XcodeBuildMCP `build_run_sim`,
  `launch_app_sim`, `snapshot_ui`, and `screenshot` as appropriate.

When Swift files are edited, agents should run:

``` sh
bash ci_scripts/tasks/format_swift.sh
```

Agents should also run the retained repository rule checks:

``` sh
bash ci_scripts/tasks/check_repository_rules.sh
```

`check_repository_rules.sh` runs SwiftLint plus repository-specific static
architecture checks that are not naturally covered by XcodeBuildMCP.
SwiftLint is resolved from the `SimplyDanny/SwiftLintPlugins` package declared
in `Cookle.xcodeproj`, not from a separately installed `swiftlint` binary.
Xcode Cloud owns formal CI builds, tests, and archives.

Helper scripts may write disposable cache data under `.build/ci/shared/`.

## Release UI Smoke Audit

Release UI smoke auditing is separate from the standard verification entrypoint.
Keep it non-destructive by default: do not erase simulator data, reset
containers, or add UI test targets solely for the audit unless explicitly
requested.
