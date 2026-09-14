# MHUI Adoption Status

Updated September 14, 2026.

## Decision and Implemented Scope

The [expanded comparison](three-way-comparison.md) was selected after Cookle
3.9 shipped. [ADR 0009](../../Decisions/0009-adopt-full-mhui-in-main-app.md)
records broader main-app adoption and narrowly supersedes ADR 0008's app
presentation boundary.

The first production-source slice includes:

- Cookle-only full MHUI product and Frameworks linkage, remote requirement
  `1.18.0..<2.0.0`, and `.mhTheme(.standard)` on the real application root.
- Recipe Detail screen scrolling, nine composed sections, grouped rows,
  adaptive ingredient values, and six semantic action buttons. Existing
  recipe content, order, navigation title, toolbar, handlers, and native
  presentations are retained.
- Native defaults for recipe sections reused by search and Intent snippets.
- Five existing app-only metric imports switched to MHUI's MHDesign
  re-export, with no metric-value changes.
- ADR, README, architecture, overview, and execution-brief updates; target
  linkage and source-import guards for the new dependency contract.

The locked MHUI version remains 1.18.0 at
`5e9841f77b770184ea560cec4831adacc1e0fdb6`. CookleLibrary, Watch, and Widgets
have no source, manifest, or lockfile changes. Deployment support, data models,
Operations, runtime bootstrap, and accent assets are unchanged. The capture
fixture remains an isolated review artifact and is not in the production app.

## Verification

- The repository Swift formatter completed. Repository rules pass, including
  SwiftLint, package consumers, Operations, test posture, model directories,
  and remote-update checks. The two new Swift files also passed explicit
  formatting and strict lint because the retained entrypoint lists tracked
  files only.
- All 43 boundary verification cases pass in disposable copies: valid
  adoption, missing actual Cookle edges despite unrelated MHUI objects,
  separate MHDesign linkage, forbidden Watch/Widgets product and framework
  links, old/branch/local package references, forbidden library dependencies,
  and ordinary, attributed, public, or scoped imports in excluded surfaces.
- Native Xcode builds of the production application succeeded with zero
  errors on dedicated iPhone and iPad simulators using Xcode 27.0 (`27A266a`)
  and iOS 27. The built MHUI checkout matches the locked 1.18 revision.
  On iPhone, the real app root and Recipe tab open a photo-bearing built-in
  Debug sample on an isolated store; the comparison bootstrap is not used.
- Production navigation checks pass for opening and closing a photo,
  ingredient and category destinations, and a related diary. Returning to
  Recipe retains the detail position. Editing opens the native form and
  Cancel returns; cooking opens and Close returns to Resume Cooking.
- Light and dark checks cover the top and six-action area without observed
  text overlap. The original orange host tint remains. A test advertisement
  rendered through the production runtime; no advertisement was activated.
- At accessibility size 1, ingredient values stack below their names and
  long edit, duplicate, and delete labels wrap to two complete lines.
- The production iPad root reaches Recipe Detail through normal creation of
  one synthetic recipe. In the light regular-width view with its sidebar,
  content cards stay at a readable 600-point width, two ingredient/value
  rows remain complete, and a long note wraps across three lines. This
  separate sample omits photos, serving size, cooking time, steps, categories,
  and related diaries. Those iPad states and iPad dark/accessibility-size
  combinations remain unverified. The five available iPad actions and footer
  fit without clipping; cooking is correctly absent because this sample has
  no steps.
- iPhone runtime logs include three SwiftUI `glassEffect()` multiple-update
  warnings. No visible defect or stopped run accompanied them in these
  checks; the cause has not been established. Simulator and monitoring
  diagnostics also remain, so the runtime log is not warning-free.
- One iPad verification run ended with SIGTERM before Recipe Detail was
  reached, after opening the Debug sample-creation action. The signal sender
  is unknown; no application exception has been established. The Create
  confirmation was not executed, and the relaunched app still had no diaries.
  The Debug path was not retried. Regular-width verification instead used
  the normal new-recipe flow described above. One TipKit detached-presentation
  warning was also recorded; its relationship to the SIGTERM is unproven.
- Verification runs and interaction sessions are stopped. The original
  Cookle scheme and iPhone 18 Pro destination were restored and confirmed;
  both dedicated simulators are shut down. No existing user simulator data
  was erased.
- Changed Markdown files pass lint, local artifact links resolve, and
  `git diff --check` passes. Source hashes remain unchanged across runtime
  builds and excluded target directories still have no changes.
- The original comparison retains 20 unretouched images across current,
  minimum, and expanded treatments. Its light, dark, and accessibility-size
  evidence is for the controlled phone fixture, not the production root.

Local verification artifacts are retained under
`.build/ci/mhui-adoption-20260914/`. MHUI package code is unchanged; upstream
1.18 evidence and Stally's application are described in the parent review.
No new library behavior tests or companion-specific builds are required by
this app-only slice.

## Remaining Main-App Rollout

Broader adoption is the selected direction. The root and Recipe Detail are
implemented; other screens are not yet converted. Each next screen retains
the same content and operations and gets focused before/after verification.

<!-- markdownlint-disable MD013 -->
| Surface | Presentation decision to apply and verify |
| --- | --- |
| Recipe, diary, and tag lists | Select native chrome, headers, and row styling; preserve existing interactions |
| Recipe, diary, and tag forms | Select native Form, header, and key-value styling; preserve fields and drafts |
| Search and settings | Style the actual app-owned containers and existing groups |
| Cooking guide | Select MHUI surfaces and actions around the existing pager and timer |
| Detached editors | Evaluate input chrome around existing native editors |
| Photo collection and metadata | Preserve grid, carousel, selection, and navigation |
| Full-screen media and system UI | Retain explicit native or owning-package presentation |
<!-- markdownlint-enable MD013 -->

This slice does not complete app-wide adoption or establish release readiness.
New features and diary-list information architecture remain separate work.
VoiceOver and remaining appearance, size-class, and production-flow checks
must be recorded for the screens they actually exercise.
