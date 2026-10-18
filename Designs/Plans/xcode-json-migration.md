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

`ci_scripts/lib/xcode_project.py` normalizes both formats with Apple's
`plutil -convert json -o -` before strict JSON parsing. Fixed copies of the
original plist and current JSON both pass all three guards. Comments, trailing
commas, URLs, and escaped string contents have fixture coverage. No Swift
interpreter or custom JSON preprocessor is required.

The initial implementation used Foundation's JSON5 reader after a failed
`plutil -lint` probe. That probe did not establish that conversion was
unsupported: direct `plutil -convert json` succeeds on the unchanged JSON.
The follow-up removes the Swift helper and its module-cache requirement.

Missing, ambiguous, linked, malformed, or unresolved project configurations
fail the checks. The filename selects the expected object model. Package
ownership follows references reachable from the legacy project root, and a
JSON product's Frameworks membership requires the target's actual Frameworks
phase. Cookle retains its own package-adoption rules, including direct
framework references.

Shared `.xcscheme` files, `ci_scripts/push_verification.json`, SwiftLint package
resolution, and Xcode Cloud's `ci_post_clone.sh` use the project bundle or
native Xcode tools; their entry points do not change. Git ignore rules retain
configuration files inside `.xcodeproj` bundles.

Historical MHUI review patches and evidence hashes under `Designs/Plans` refer
to the configuration used for those observations. They remain historical
artifacts, not parsers or instructions to patch the converted project.

## Semantic qualification

Conversion uses Xcode 27.2's File inspector **Project Format → JSON** action.
The generated JSON is kept as Xcode wrote it. A disposable copy is converted
back with `xcodebuild -convert-project pbxproj` for a structural comparison
against the original configuration; that selector is recorded in the original
execution log. A later disposable copy also confirms the named selector
`xcodebuild -project App.xcodeproj -convert-project 'Xcode 27.0'` on Xcode 27.2.
Neither reverse conversion is an exact restoration procedure.

The comparison resolves regenerated object references and checks all three
targets, their eight Debug/Release configurations, target/product IDs used by
schemes, package locations and requirements, build phases, embedding settings,
target dependencies, synchronized folders and membership exceptions, resources,
and localizations. Their values and memberships match. The comparison treats
Frameworks inputs and package-product declarations as sets; it does not prove
that their order is preserved. Xcode regenerates internal object IDs and
normalizes inferred file types and default flags; old target creation-version
annotations are omitted.

The native reverse conversion exposes these Frameworks-phase input orders:

<!-- markdownlint-disable MD013 -->

| Target | Before conversion | After conversion |
| --- | --- | --- |
| Cookle | MHPlatform, MHAppRuntimeAds, CookleLibrary, MHUI | CookleLibrary, MHAppRuntimeAds, MHPlatform, MHUI |
| Widgets | SwiftUI.framework, CookleLibrary, WidgetKit.framework | CookleLibrary, SwiftUI.framework, WidgetKit.framework |
| Watch | CookleLibrary | CookleLibrary |

<!-- markdownlint-enable MD013 -->

The order differences are retained as an observation. Equal membership and
settings do not establish identical linker input order. The successful app and
embedded-target build and library tests below bound the behavior observed with
the converted configuration.

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
| Initial repository rules | At `07d83c32`: SwiftLint, retained repository guards, and 21 tooling tests, including nine dual-format project checks. |
| Handoff follow-up | At `598ccf9a`: evidence-mode repository rules pass; SwiftLint 0.65.1 checks 667 files with zero captured errors/warnings; all 28 tooling tests pass, including 16 project checks. |
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

The handoff follow-up changes only repository tooling and this record. The
original and converted project hashes are unchanged. It rejects reproduced
missing-phase, wrong-model, unattached-owner, and symlink cases, with coverage
for wrong package ownership and direct framework boundary violations. The
updated shared lint matcher also accepts the actual execution evidence against
the JSON stored in source commit `598ccf9a`; no publication receipt is created.
The earlier app build and 565-test execution remain earlier evidence, rather
than a new build/test run or authorization to publish the follow-up.

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
