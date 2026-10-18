# Xcode JSON project migration

## Scope and compatibility

Issue [#154](https://github.com/muhiro12/Cookle/issues/154) changes only the
configuration file inside `Cookle.xcodeproj` from `project.pbxproj` to
`project.xcproj`. The bundle path, shared schemes, package resolutions, app
version, deployment targets, signing settings, entitlements, source code,
resources, and persisted data remain unchanged.

The minimum project reader is Xcode 27. Apple provides format conversion in
Xcode 27.2 and later; ordinary development does not require 27.2. The owner
confirmed that the existing Xcode Cloud environment already uses Xcode 27.
That confirmation does not establish a Cloud build of the converted candidate.
This change neither upgrades the deployment targets nor makes JSON conversion
a prerequisite for separate Duo qualification.

References:

- [Apple conversion and compatibility guidance][conversion]
- [Apple project-format schema][schema]

## Dependency audit before adoption

<!-- markdownlint-disable MD013 -->

| Consumer | Required adjustment |
| --- | --- |
| `ci_scripts/tasks/check_environment.sh` | Discover exactly one configuration and inspect the remote SwiftLint package structurally. |
| `ci_scripts/tasks/check_test_posture.sh` | Inspect target types in either format instead of searching plist syntax. |
| `ci_scripts/tasks/check_package_consumer_boundaries.sh` | Replace plist-specific `awk` extraction with package and Frameworks-edge checks. |
| `ci_scripts/lib/check_mhui_project_links.py` | Replace the plist-only checker with `check_project_configuration.py` and a shared reader. |
| `README.md` | Require Xcode 27 or later and document the JSON configuration. |

<!-- markdownlint-enable MD013 -->

`ci_scripts/lib/ReadXcodeProject.swift` uses Foundation's JSON5 reader because
Xcode emits trailing commas. The reader accepts comments and preserves string contents
without maintaining a custom JSON preprocessor. Legacy configurations continue
through Apple's `plutil`, allowing an isolated conversion revert. Missing,
ambiguous, malformed, or unresolved project configurations fail the checks.

Shared `.xcscheme` files, `ci_scripts/push_verification.json`, SwiftLint package
resolution, and Xcode Cloud's `ci_post_clone.sh` use the project bundle or native
Xcode tools; their entry points do not change. Git ignore rules already retain
configuration files inside `.xcodeproj` bundles.

Historical MHUI review patches and evidence hashes under `Designs/Plans` refer
to the configuration used for those observations. They remain historical
artifacts, not parsers or instructions to patch the converted project.

## Semantic qualification

Conversion uses Xcode 27.2's File inspector **Project Format → JSON** action.
The generated JSON is kept as Xcode wrote it. A disposable copy is converted
back with `xcodebuild -convert-project pbxproj` for a structural comparison
against the original configuration.

The comparison resolves regenerated object references and checks all three
targets, their eight Debug/Release configurations, target/product IDs used by
schemes, package locations and requirements, build phases, embedding settings,
target dependencies, synchronized folders and membership exceptions, resources,
and localizations. These values match. Xcode normalizes internal object IDs,
inferred file types, default flags, and package/framework listing order; old
target creation-version annotations are omitted. Those serialization changes
are distinguished from the preserved configuration values.

Xcode 27.2's resolved Cookle Debug Simulator settings and Release device
settings also match exactly before and after conversion. Native target,
configuration, and scheme discovery is unchanged. Shared schemes and committed
package resolutions have no diff. The Archive actions continue to use Release.

## Local verification on 2026-10-18

<!-- markdownlint-disable MD013 -->

| Boundary | Evidence |
| --- | --- |
| Conversion and structural comparison | Xcode 27.2 (`27B5038j`); preserved configuration values described above. |
| Earlier project reader | Xcode 27.1 (`27A9275`); all targets, configurations, and schemes discovered. |
| App and embedded targets | Xcode 27.1 Debug Simulator build of Cookle, Widgets, and Watch succeeds; complete CLI output has no warnings or errors. |
| Normal regression plan | Xcode 27.2, iOS 27.2, Cookle's assigned iPhone 17 Simulator; all 565 tests pass. |
| Repository rules | SwiftLint, retained repository guards, and 21 tooling tests, including nine dual-format project checks. |
| Schema research | The two synthetic future-schema cases are separate observations, not downgrade-safety proof. |

<!-- markdownlint-enable MD013 -->

The normal tests deliberately reject read-only legacy migration, a read-only
extension save, corrupt store opening, and corrupt-destination validation.
Their emitted errors require individual review against the passing assertions;
test success alone does not mean an empty diagnostic log. Keep the original
capture and its diagnostic counts when recording that review.

An initial Xcode 27.2 test build also emitted an App Intents metadata-extraction
warning for the presentation-free library. `CookleLibrary` has no App Intents
implementation. Its test-only rerun uses Apple's
`LM_SKIP_METADATA_EXTRACTION=YES`; that setting is not added to the project or
the app build. The original warning remains in the initial execution record.

Local builds, tests, and Release-setting inspection do not prove a signed
archive, TestFlight build, or Xcode Cloud run. Issue
[#125](https://github.com/muhiro12/Cookle/issues/125) retains the existing release
operations boundary; no new workflow is introduced.

## Rollback

The format replacement is committed separately from the compatible checker
updates. To restore the previous configuration, revert that conversion commit
as a unit with `git revert 0b16bf70`. It removes `project.xcproj` and restores
`project.pbxproj`; do not
retain both files in the bundle. The checker updates can stay in place.

Before reverting, preserve any subsequent project-setting changes and review
the resulting configuration. Reopen the project, rediscover schemes, and rerun
the affected build and test checks. This rollback changes project configuration
only; it is not an application-data or binary downgrade procedure.

[conversion]: https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format
[schema]: https://github.com/apple/xcode-project-format
