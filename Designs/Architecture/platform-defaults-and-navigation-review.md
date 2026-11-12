# Platform defaults and navigation review

Review for [#160](https://github.com/muhiro12/Cookle/issues/160) and
[#156](https://github.com/muhiro12/Cookle/issues/156), starting at `c5865571`
on 2026-11-12. Incomes #412 and #402 supply review questions, not Cookle's
presentation or persistence requirements.

## Navigation decisions

Apple's [NavigationSplitView documentation](https://developer.apple.com/documentation/swiftui/navigationsplitview)
describes selection-driven lists and native disclosure chevrons when collapsed.
Use that behavior for destinations within native lists. Preserve the existing
split containers, shared selection, route handling and editor ownership.

| Surface | Result | Decision |
| --- | --- | --- |
| Settings: Subscription, Advanced, Licenses | Split detail, collapsed push | Use `List(selection:)` and `NavigationLink(value:)`; remove plain button styling and manual hit-area wrapping. |
| Recipe list and search results | Recipe detail | Use native selection links; retain sorting, query ownership and recipe identity. |
| Category/ingredient lists | Tag content column | Use native selection links; retain clearing of the old recipe when the selected tag changes. |
| Recipes in diary, tag and photo details | Recipe detail column | Use native selection links; leave edit/delete actions as buttons. |
| Diary history | Selection-driven detail from grouped stack rows | Keep existing selection action and full-row hit area; add a compact-only, accessibility-hidden forward chevron. These rows are outside `List`. |
| Today's diary | Diary detail | Retain the explicit “View Today's Diary” label and its existing cue. |
| Diary recipe inspiration | Switch to Recipe tab and select recipe | Retain the action and accessibility hint; do not imply an in-column push. |
| Photo grid | Select a photo | Retain image buttons with photo-specific accessible names; do not add list arrows to thumbnails. |
| Photo preview, Add/Edit, Debug | Modal presentation | Retain buttons and native sheets/full-screen covers. |
| Ingredient/category text in Recipe detail | Open the tag-browser sheet | Retain route-based buttons; the links inside that sheet own hierarchical disclosure. |
| Return/resume cooking row | Resolve current target, optionally open cooking modal | Retain explicit action wording and target revalidation. |
| Import conflict/review and diary meal selection | Hierarchical destination | Existing native links remain. |
| Export/import launch, permission, privacy options, reset tips | Action or modal/system flow | Retain buttons; no disclosure chevrons. |
| Notification mode, time and iCloud preference | Change a value | Retain picker/date picker/toggle and existing eligibility guards. |
| Dates, notes, subscription state | Reading | Retain noninteractive content. |

The subscription tip event follows the selected destination instead of a tap
gesture, so the link's native activation owns interaction semantics.

## Explicit-setting inventory

This inventory groups meaningful production choices rather than treating every
spacing constant, required parameter or localized string as an override.
“Retain” means removal has no demonstrated benefit in this review; it does not
claim every numeric value is optimal.

| Boundary and source | Default or alternative | Decision and removal consequence |
| --- | --- | --- |
| All six split navigation hosts: sidebar width and split style | Framework-selected width and automatic style | Already unspecified, including inspected MHUI container modifiers. Keep defaults. |
| Split visibility `.all` and `CompactSplitColumnPolicy` | Automatic visibility/compact-column inference | Retain list-first startup and explicit routed selection. Removing these changes navigation and reselection, not just appearance. |
| `MainTabView`, root sheets and recipe-form host | Native tabs, sheets and automatic sheet presentation | Retain tab roles, search-tab activation and editor ownership. No app detent, drag-indicator or corner-radius overrides were found. |
| `SettingsSidebarView` bottom content margin, 96 points | Native list scroll margin and safe area | Remove fixed extra margin; inspect the last row and scrolling in compact and wide settings. |
| `CookleSplitSidebarModifier`, MHUI `MHContainerContent` and `mhListChrome` | Native list style, surfaces and spacing | Retain content/plain-list presentation and expanded native sidebar backgrounds. Settings omits `MHContainerContent`: its native-mode row background obscures selected-row fill on iPad. Keep the canvas modifier and let the OS draw setting rows. No shared package change. |
| Settings notification picker and recipe sorting menu | Automatic picker style depends on container/platform | Retain explicit menu presentation for the small choice set and nested sorting menu. Do not silently change the interaction. |
| `CookleWrappingLargeTitleModifier`, empty-state readable width, title/icon sizing | Native title truncation or unconstrained content | Retain existing wrapping and readable-width choices; these are layout adaptations, not fixed sidebar widths. |
| Photo grid 120-point adaptive minimum, preview 240-point height, image requests | Required app layout/image-size choices | Retain bounded gallery density and decoding sizes. Removing dimensions does not provide an equivalent automatic gallery. |
| Tag/search input capitalization, correction and keyboard dismissal | System text-input heuristics | Retain literal query entry and existing scroll/keyboard interaction. |
| `CookleTipController`: daily display frequency | TipKit defaults to immediate | Retain intentional frequency limit; removing it can show tips more often. Application-default datastore is an explicit standard location. |
| `RecipeFoundationModelInferenceOperations`: greedy sampling | Framework-selected sampling with default `GenerationOptions` | Retain extraction-oriented sampling, grounding, cancellation and unsaved draft flow. A quality corpus comparison is required before changing it. |
| PCC recipe generation | App instructions, model choice and availability policy | Retain explicit product policy and editable drafts. It is distinct from on-device text extraction; no automatic model substitution. |
| `RecipeWebsiteReader`: nonpersistent store, playback restriction | WebKit's persistent default store and framework media policy | Retain privacy and non-playing import surface. Do not make website import retain browsing data as incidental cleanup. |
| Website 30-second load/15-second extraction, 10 navigations, 3 MB response limits | `URLRequest` defaults to 60 seconds; no equivalent aggregate extraction/navigation limits | Retain current safeguards in this UI change. A slow-network comparison of 30 versus 60 seconds remains useful before changing the timeout; HTTP success range is validation. |
| `CooklePhotoImageCache`: 64 MiB and 128 entries | `NSCache` limits default to zero (no configured limit) | Retain advisory resource bounds; eviction timing remains framework-owned. Exact tuning needs measurement. |
| Image hashing/decoding/compression and archive/import tasks | Unspecified detached-task priority | Retain `.userInitiated` for work a person is waiting for, plus cancellation propagation. No scheduling or performance claim is made. |
| `PhotoImageProcessor`: 500 KiB and 2048-pixel stored image targets | App-supplied encoding/downsampling policy | Retain storage/sync cost and image normalization behavior; this changes stored output and requires separate image-quality evidence. |
| Notification authorization, foreground delivery and adaptive/fixed/off schedules | System permission and delivery, with app-supplied requests | Retain request timing, preference preservation and bounded schedules. Permission is not a duplicate app preference. |
| Review policy and mutation workflow | StoreKit controls whether a submitted review request appears | Retain the existing one-in-ten request policy and two-second delay; system throttling does not supply Cookle's eligibility semantics. |
| Widget providers and next-day refresh policy | Timeline entries/policy are app-supplied; WidgetKit owns actual execution | Retain calendar-aware next-day requests and empty/error behavior. `.atEnd` is not a guaranteed execution time. |
| Widget line limits/scaling and Watch 44-point control minimum/pager layout | Unconstrained text and native intrinsic control sizes | Retain bounded widget content and usable Watch controls. Companion UI is unchanged. |
| Library persistence, archive/version/resource limits, dates, identifiers, CloudKit | Framework defaults do not express Cookle's data contracts | Retain save/rollback ownership, local-calendar semantics, portable-file validation, released identifiers and user preferences. |
| Info.plist, capabilities, deployment/device families, URL/file declarations | Required declarations or absence of a capability | Retain product/platform contracts. No full-screen or fixed-orientation restriction was introduced. |

Relevant defaults are documented by Apple:
[TipKit frequency](https://developer.apple.com/documentation/tipkit/tips/configurationoption/displayfrequency(_:)),
[NSCache total cost](https://developer.apple.com/documentation/foundation/nscache/totalcostlimit),
[NSCache count](https://developer.apple.com/documentation/foundation/nscache/countlimit),
[WebKit data storage](https://developer.apple.com/documentation/webkit/wkwebviewconfiguration/websitedatastore),
and [request timeout](https://developer.apple.com/documentation/foundation/urlrequest/timeoutinterval).
Required `Timeline`, grid and image-processing inputs are not removable
defaults.

## Verification

Verification uses Xcode 27.2 (27B52), selected by `xcode-select`, Cookle's
assigned iOS 27.2 Simulators, the Debug build and existing development samples.
No data/schema, wire format, package version, notification policy, model
inference or image processing behavior is changed.

- The final app build passed with no warning/error diagnostics. The complete
  `CookleLibrary` plan passed all 720 tests, with none failed or skipped and no
  raw `warning:` lines. The console retains image-decoder diagnostics and
  store-failure messages, including corrupt/read-only fixture tests; this is
  not a zero-runtime-diagnostics claim. SwiftLint formatting and retained
  repository rules passed, including 28 rule-script tests.
- iPhone 18 Pro, portrait: before/after captures show native disclosure on
  Settings and Recipe list destinations. Advanced and Recipe detail support
  Back followed by reselecting the same row. Licenses opens and returns
  normally.
  Diary history opens the diary; its recipe link opens the expected recipe.
  The final Shortcuts row remains visible/reachable with native scroll margins.
- Accessibility hierarchy retains button roles and existing content labels.
  This is not a claim of actual VoiceOver speech/focus verification.
- iPhone accessibility XXXL, applied only to the verification launch: Settings
  labels wrap, disclosure remains visible, and the final Shortcuts control is
  reachable. A wrapped recipe row still opens its detail. Existing one-line
  ingredient/category summaries remain truncated visually and retain their
  full accessibility labels; this review does not change that content policy.
- iPad Pro 11-inch, landscape: Settings switches between Advanced and Licenses
  with readable native selected-row fill; expanded sidebar links do not add
  duplicate disclosure indicators. The first comparison exposed white selected
  text over the custom pale row background. Removing that row background fixed
  the contrast on a new build. Recipe selection already used native fill and
  displayed the correct detail.
- Duo fold transitions remain unqualified in this run. The initial Xcode
  connection failure recovered after session recreation, but shared Device Hub
  focus and an unusable capture prevented reliable open/closed evidence.
  This review does not complete the separate device-qualification issue.
- Final iPhone Settings captures confirm readable native rows, disclosure and
  the final Shortcuts control after the iPad background fix. Search accepts a
  Japanese query with the keyboard, opens the matching recipe through a native
  result link, and retains the query after Back.
- Category list to category detail to recipe detail passed on iPhone. The
  recipe context menu still exposes its secondary actions and dismisses without
  invoking them. All verification sessions ended; the Cookle scheme and its
  original iPhone destination were restored after UI checks.

Remaining coverage: photo-linked recipe-row interaction, unsaved editor drafts
across resizing, physical devices, actual VoiceOver, older supported OS
versions,
and selected-state Duo fold transitions. Maximum Dynamic Type evidence precedes
the Settings row-background fix; normal-size final Settings was checked again.
Simulator runtime logs include unavailable telephony/haptic diagnostics, so UI
success is not a claim of zero runtime diagnostics. No UI crash was observed.

The non-UI choices above are retained, not newly quality/performance-qualified.
The extraction sampler, image/cache limits and website timeout need a separate
bounded comparison before any behavioral change. These evidence gaps remain
explicit; neither issue is closed by this local review.
