# Cookle MHUI 1.18 Adoption Review

> Status: Expanded direction accepted on September 14, 2026. The root and
> Recipe Detail are now the first production-source adoption slice. See
> [implementation status](mhui-1.18-comparison/adoption-status.md) and
> [ADR 0009](../Decisions/0009-adopt-full-mhui-in-main-app.md).

The follow-up [three-way comparison][three-way] adds an expanded MHUI option.
Its [supplemental review][expanded-review] records the extra composition scope
and adoption checks. Expanded composition was selected after that comparison.
The original minimum recommendation and capture evidence below are retained
as review history, based on commit `0a9eda1`. They do not describe the current
production dependency boundary.

## Original Minimum Recommendation

Use MHUI's native-container route for the minimum main-app migration. The
[Recipe Detail comparison](mhui-1.18-comparison/comparison.md) supplies the
first review slice with the existing content, section order, controls,
navigation, and action handlers. Approval of this direction precedes expansion
across the main app.

Full adoption means a root theme plus an explicit presentation decision at
each app-owned screen boundary. It does not require using every MHUI primitive,
replacing native rows, introducing a summary, or moving actions. A deliberate
native exception remains valid for specialized media and system UI.

The native-container approach is a viable adoption candidate. Keep section
headers opt-in during rollout: the all-seven-header variant shown here is a
visual choice, not a requirement for full adoption. Its stronger section cues
cost approximately 44 points above the ingredient block at standard text size.
Accept it if that separation is preferred; if first-viewport density matters
more, revise and recapture the same screen before accepting a smaller header
treatment. Do not silently treat an unrendered variant as approved.

The [original brief](near-term-development-brief.md) still controls sequencing:
the September release must be complete before production adoption, and visual
approval must precede broad migration. This review does not establish release
completion or change the iOS 18 deployment target.

## Evidence at the Comparison Baseline

<!-- markdownlint-disable MD013 -->
| Source | Inspected state | Meaning |
| --- | --- | --- |
| Cookle | `main`, `0a9eda1be5b24217ad69082f5862d406051e8248` | Clean tracked starting tree; six local commits ahead of origin |
| Cookle dependency | `CookleLibrary/Package.resolved`: MHUI `1.18.0`, revision `5e9841f77b770184ea560cec4831adacc1e0fdb6` | A resolved package is not a linked product |
| Cookle app target | `MHDesign` framework/product, remote minimum `1.0.0` | ADR 0008 and the current boundary check still prohibit full MHUI linkage |
| MHUI | Tag `1.18`, same `5e9841f` revision | Source and adoption guide inspected; no package changes made |
| Stally | `36a00d0`; adoption reconciliation `56675db` | Actual source and lockfile inspected; unrelated planning changes preserved |
| Toolchain | Xcode 27.0, build `27A266a`, selected from Xcode-beta | Comparison environment only; no distribution claim |
<!-- markdownlint-enable MD013 -->

MHUI's versioned `Designs/Guides/ADOPTION_GUIDE.md` explicitly treats native
List and Form as complete styled adoption paths. Its guidance makes row
chrome optional and reserves `mhInputChrome` for inputs outside native Form.
The same revision's README still emphasizes signature composition more
strongly. Use the specific native-container guidance and current Stally
implementation for this bounded migration; do not infer a stack conversion
requirement from the README's emphasis.

Stally provides concrete, reusable evidence:

- `StallyApp.swift` applies `.mhTheme(.standard)` and automatic glass policy.
- `ItemDetailView.swift` retains List, native sections, navigation, sheets,
  alerts, and action handlers. Its existing bottom action bar and scroll-edge
  modifier precede `.mhListChrome()`.
- `ItemFormFields.swift` retains native fields and sections. The shared
  `stallyFormChrome` adapter adds the canvas and key-value styling; it does not
  wrap every field in `mhRow` or `mhInputChrome`.
- The September 13 section of `docs/ui-preview-report.md` reconciles exact
  MHUI 1.18 dependency evidence with an earlier Debug build and development
  archive. The July gallery is historical, and its old stack-based detail
  does not prove the current List implementation's appearance.

These are source and recorded-evidence findings. No Stally tests, build, or
runtime audit were repeated for this Cookle proposal.

## Representative Screen: Recipe Detail

Use `Cookle/Sources/Features/Recipe/Views/RecipeView.swift`. It is a core
reading screen with photos, grouped recipe content, linked ingredients,
linked diaries, and a complete action section. It exercises a useful MHUI
boundary without redesigning the diary list or introducing a new feature.

<!-- markdownlint-disable MD013 -->
| Contract | Current | Candidate |
| --- | --- | --- |
| Screen container | Native List | Same List plus `mhListChrome` |
| Theme | Existing MHDesign metrics | `mhTheme(.standard)`, host tint inherited; accent assets unchanged |
| Heading | Recipe navigation title | Same title and toolbar |
| Section hierarchy | Native text headers | Same seven titles through `MHSectionHeader` |
| Rows and separators | Native grouped rows | Same native rows and separators |
| Photos | Existing horizontal carousel and photo destination | Unchanged |
| Ingredients and categories | Existing button rows and route delivery | Unchanged |
| Steps | Existing numbering, order, and text | Unchanged |
| Metadata and related diaries | Existing rows and routes | Unchanged |
| Actions | Cooking, share, add to today's diary, edit, duplicate, delete | Same order, handlers, and confirmations |
| New summary or floating bar | None | None |
<!-- markdownlint-enable MD013 -->

The candidate changes seven header components: serving size, cooking time,
ingredients, steps, categories, note, and related diaries. The last one is a
section on Recipe Detail, not the diary list. Empty-section conditions,
formatting, photo presentation, metadata, and action implementations remain
identical. All affected components belong to the Cookle app target.

The small vertical slice is supplied as an **unapplied**
[implementation patch](mhui-1.18-comparison/recipe-detail-candidate.patch).
It changes the app product reference, root theme, Recipe Detail container,
and those seven header components. It is a comparison implementation, not a
complete adoption commit: the policy changes below must accompany adoption.

### Capture Contract and Ledger

Both sides use Xcode 27.0 (`27A266a`), iOS 27.0, a dedicated iPhone 18 Pro
simulator, Japanese language/locale, and the same in-memory carbonara fixture.
The viewport is 402 by 874 points. Light and dark use Dynamic Type Large;
the large-text pair uses accessibility size 1. Sample order, fallback color,
and relative sample dates are fixed. The primary recipe has no photos and no
configured ads. The [capture fixture patch][fixture] keeps this setup separate
from product changes.

The live fixture opens the actual RecipeView in a NavigationStack, bypasses
production bootstrap, and uses a nonpersisting cooking-session store. Existing
service initialization still emits CloudKit NoAccount errors; the fixture does
not disable every CloudKit startup path. Its dedicated simulator has no account
and no user store. No backup or real-account state is used for setup.

<!-- markdownlint-disable MD013 -->
| Capture | Status | Evidence or blocker |
| --- | --- | --- |
| Original main Recipe Detail Preview | Failed | Xcode reported `PreviewFailedError`, Cookle abort, and `swift_task_dealloc` in the Swift Concurrency stack; no image returned |
| Isolated current-source direct Preview | Mixed | One render succeeded; subsequent deterministic-fixture renders aborted or timed out |
| Isolated current live comparison | Captured | Six original screenshots: light, dark, large text, reading, related content, actions |
| Isolated MHUI live candidate | Captured | Six matching screenshots from the same fixture plus only the candidate's product, theme, canvas, and seven headers |
| Regular width and VoiceOver | Not attempted | Remain rollout checks; the phone screenshots do not prove them |
<!-- markdownlint-enable MD013 -->

The direct Preview failures do not establish an MHUI defect. Explicit
main-actor fixture setup did not reliably resolve them. A native live run of
the same RecipeView is the comparison fallback; no mockup or historical Stally
image substitutes for a Cookle capture. Xcode-native transport later closed;
the official `xcrun mcpbridge` connection recovered native build/run/capture
capabilities without restarting Xcode.

An initially stale 1.15 package resolution was discarded. The isolated project
requires 1.18, and the successful comparison builds use revision `5e9841f`.
No 1.15 image is included in the comparison.

### Visual Findings

- Light appearance uses a paler canvas, darker section-title text, and short
  rules above the existing titles. Native row backgrounds and separators stay
  in place. No additional summary, card grouping, or action bar is introduced.
- Dark appearance changes the black canvas to dark charcoal and makes section
  labels brighter. Native dark rows and separators remain readable in the
  captured first viewport; the same vertical-density tradeoff remains.
- Accessibility size 1 preserves the visible ingredient labels and values
  without new overlap or clipping. Extra header space moves the final salt row
  below the candidate's initial viewport. This comparison covers that first
  viewport, not every large-text scroll position or accessibility size.
- Standard-size native ingredient rows remain approximately 52.3 points high.
  Section headers grow from approximately 40.3 to 55.0 points. The first step
  falls below the candidate's initial viewport; scrolling still exposes the
  unchanged recipe. These measurements come from native UI hierarchy frames.
- The long navigation title already truncates in the current screen. Existing
  English servings/minutes values also remain unchanged. Neither is an MHUI
  regression or part of this proposal's localization scope.
- Both live sides inherit a blue toolbar/action tint. An earlier direct Preview
  used orange. The candidate changes no accent asset or explicit native tint;
  verify production-root accent propagation during adoption. These captures
  establish the relative canvas and header treatment, not shipping tint parity.

The comparison isolates a photo-free recipe state. It does not prove the photo
carousel, photo viewer, advertising, or production root navigation. Ingredient,
category, and diary route handlers remain unchanged in source, but route
delivery needs the production navigation shell and separate runtime evidence.

### Runtime Coverage

Both sides scrolled through the recipe, opened the existing edit sheet and
returned with Cancel, and entered the cooking guide at step 1 of 6 before
closing it. Closing showed the existing Resume Cooking state. Action images
were taken before entering cooking, so both show Start Cooking. No save,
duplicate, delete, share submission, diary insertion, timer, or cooking
completion was executed.

Native hierarchy evidence confirms identical action labels and bottom-anchored
action/footer frames. Reading captures align the first step within 3.7 points;
the note-body alignment differs by less than 0.4 points. Intermediate scroll
offsets intentionally align content, since section heights differ.

The bounded runs did not crash. Logs include the shared NoAccount CloudKit
initialization error, simulator telephony messages, and an accessibility
duplicate-class warning. Successful rendering does not make those logs clean
or establish CloudKit, production bootstrap, or VoiceOver correctness.

## Original Minimum Main-App Migration Proposal

<!-- markdownlint-disable MD013 -->
| Area | Minimum treatment | Preserve |
| --- | --- | --- |
| App root | Link MHUI; apply one standard theme; use its MHDesign re-export | Bootstrap, app identity, AccentColor, current deployment support |
| Recipe, diary, tag lists and grouped detail | `mhListChrome`; approved header treatment where useful | Queries, sorting, filtering, suggestions, row content, swipe/edit behavior, routes |
| Recipe, diary, tag forms | `mhFormChrome`; selective headers | Native fields, focus, keyboard, pickers, photo controls, validation, drafts, save/cancel |
| Search and settings | Apply chrome at their actual app-owned List boundary | Search semantics, setting groups, subscription and backup behavior |
| Cooking session | Replace app-owned canvas/surface/action treatments only where MHUI owns the same role | Step pager, timer, progress, enabled states, order, close/end confirmations |
| Detached text and inference editors | Evaluate `mhInputChrome` and semantic canvas around existing native editors | Input contents, placeholder behavior, inference, keyboard, Done/Cancel |
| Photo collection and metadata | Style app-owned collection/detail chrome where appropriate | Grid/carousel/paging, image dimensions, selection, navigation |
| Full-screen photo viewer | Explicit native exception | Black media canvas, full-width paging, close control |
| System and package-owned presentations | Keep native or owning-package appearance | Photos picker, camera, share sheet, alerts, TipKit, StoreKit/license UI, advertisements |
| Debug and Preview routes | Inherit root baseline; explicit native exceptions where needed | Debug controls and separation from product behavior |
<!-- markdownlint-enable MD013 -->

The five current `import MHDesign` files can switch to `import MHUI` when the
main app standardizes imports. This is app-local housekeeping, not a change
to the metrics API or values. Do not move generic layout helpers, screen
models, routes, or services into MHUI.

Do not change diary-list information architecture, suggestions, section
ordering, filters, recipe semantics, or add an overview merely to demonstrate
MHUI. Cooking-session and custom-editor treatments need their own focused
before/after evidence during rollout; this one screen cannot approve them.

CookleLibrary, Watch, and Widgets are excluded from implementation. Their
existing no-MHUI/no-MHDesign constraints remain enforced. App Intents remain
behavior adapters; main-target linkage does not justify MHUI imports there.

## Adoption-Time Policy Change Set (Now Implemented)

The release and visual gates are satisfied. ADR 0009 now supersedes **only
the Cookle app presentation bullets** of ADR 0008. The checklist below records
the required adoption contract; implementation and current verification are
tracked in [adoption status](mhui-1.18-comparison/adoption-status.md).

Original proposed decision text (ADR 0009 records the expanded selection):

> Cookle adopts the full MHUI product in its main app for the standard theme,
> native-container chrome, and explicitly selected semantic presentation.
> Native List and Form are complete adoption routes. Cookle owns product
> composition, wording, navigation, state, behavior, and its accent assets.
> Specialized native and package-owned subtrees may retain their presentation.
> CookleLibrary, Watch, Widgets, and App Intent implementations gain no new
> presentation dependency. MHUI adoption does not change deployment support.

<!-- markdownlint-disable MD013 -->
| File | Required adoption change |
| --- | --- |
| `Cookle.xcodeproj/project.pbxproj` | Replace the Cookle-only MHDesign product and framework reference with MHUI; require at least `1.18.0` in the existing next-major range |
| App Xcode resolved state | Confirm actual built checkout is the approved MHUI revision; the currently inspected tracked lock already has 1.18.0 |
| `Designs/Decisions/0009-...md` | Record approval evidence, native routes, explicit exceptions, and narrowly superseded ADR 0008 bullets |
| `README.md` | Replace all metrics-only app claims in layout, technology stack, and architecture posture |
| `Designs/Architecture/ARCHITECTURE_GUIDE.md` | Describe main-app full adoption and preserve behavior/presentation ownership |
| `Designs/Architecture/shared-service-design.md` | Update only the main-app presentation bullet; preserve platform and library rules |
| `Designs/Overviews/cookle-current-overview.md` | Record actual implemented scope and native exceptions after code lands |
| `Designs/Plans/near-term-development-brief.md` | Record the accepted slice and remaining rollout, then retire when its mission is complete |
| `ci_scripts/tasks/check_package_consumer_boundaries.sh` | Replace metrics-only requirement/prohibition with explicit Cookle-only MHUI requirements and retain all excluded-surface checks |
<!-- markdownlint-enable MD013 -->

The boundary check must do more than remove the current MHUI rejection:

1. Require MHUI in the Cookle target's package products **and Frameworks build
   phase**. Reject a separate direct MHDesign product link once imports use
   the re-export. Resolve product IDs per target; an unrelated global string
   match must not satisfy this rule.
2. Raise the MHUI remote minimum assertion from `1.0.0` to `1.18.0`, retaining
   the next-major requirement and prohibitions on branch and local paths.
   Raise the resolved-version floor from `1.5` to `1.18` for the adopted state.
3. Continue rejecting MHUI/MHDesign links and imports in CookleLibrary, Watch,
   and Widgets. Retain the existing MHPlatform, Operations, test-posture, and
   generic-utility restrictions.
4. Add a source import guard for main-target App Intent implementations.
   Preserve their behavior-adapter role even though their app target links MHUI.
5. Verify the changed checker with positive adoption state and negative cases:
   missing Cookle MHUI linkage, separate MHDesign link, old/branch/local
   requirement, and MHUI/MHDesign leakage to each excluded surface and the
   main-target App Intent implementations. Use
   disposable copies; do not mutate those product targets to exercise checks.

These policy changes accompany the accepted Recipe Detail implementation.
The resolved MHUI 1.18 pin was already present and remains unchanged.

## Historical Proposal Checks

- The unapplied candidate passes `git apply --check` against the inspected
  main commit. This proves patch applicability, not compilation or behavior.
- The isolated fixture and candidate pass the repository Swift formatter.
- All three review Markdown files pass markdownlint with zero issues; relative
  artifact links resolve and `git diff --check` passes.
- A complete app-source comparison between capture sides contains only nine
  changed Swift files: app root, RecipeView, and seven existing headers.
- Native candidate build evidence reports success without build errors, and
  both variants ran on the dedicated simulator. Twelve original captures are
  retained in the paired gallery; none are generated or retouched.
- `check_repository_rules.sh` passes, including SwiftLint and all current
  package, Operations, test-posture, model-directory, and update checks.
- At comparison capture time, the main checkout had no tracked source or
  dependency changes; only the review and comparison inputs were new files.
- Live interaction evidence is confined to the disposable project and
  dedicated comparison simulator.
- The verification run and interaction session are stopped. The isolated
  project's original scheme and destination were restored before closing it;
  its dedicated simulator was shut down. The main project's original Cookle
  scheme and iPhone 18 Pro destination were confirmed unchanged.

## Approval Criteria and Verification

Approve the phone visual direction only if the comparison shows:

- Exactly the same facts, labels, section order, and available actions.
- Recipe content remains dominant; section emphasis helps scanning without
  introducing duplicate titles or excessive vertical gaps.
- Native grouping and scrolling remain clear. Controls retain their roles,
  touch areas, enabled/disabled distinction, and destructive confirmations.
- Light and dark appearance and large text remain readable. This approval
  selects a direction; regular width, VoiceOver order, and actual production
  route behavior remain implementation checks, separate from these images.

Apple's [materials guidance][materials] places Liquid Glass in navigation and
control layers and distinguishes content materials. For Cookle this supports
retaining a stable recipe reading plane and native toolbar treatment. Do not
put glass on recipe text blocks merely to increase visual difference.

For the adoption change, run the formatter and repository rules, build Cookle
through Xcode, and capture the affected screens. Check the exact MHUI package's
tests/rules and relevant Preview evidence. Exercise Recipe Detail scrolling,
photo opening, ingredient/category and diary routes, editing, sharing, cooking
entry, and confirmation presentation using isolated fixtures. Never execute a
destructive real-data action for a visual review.

No new library tests or companion builds are justified by this comparison
alone. Broaden verification only if the eventual change actually crosses those
boundaries. Screen images and a successful build do not prove persisted-data,
purchase, distribution, or overall release readiness.

[materials]: https://developer.apple.com/design/human-interface-guidelines/materials
[fixture]: mhui-1.18-comparison/capture-fixture.patch
[three-way]: mhui-1.18-comparison/three-way-comparison.md
[expanded-review]: mhui-1.18-comparison/expanded-review.md
