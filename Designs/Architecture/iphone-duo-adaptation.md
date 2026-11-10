# iPhone Duo Adaptation

## Scope

Cookle treats opening and closing iPhone Duo as a scene resize. The app retains
its standard tabs, split navigation, recipe editor, and cooking workflow. The
minimum deployment target remains iOS 18.

## Layout and State

- Keep one `NavigationSplitView` per browsing surface across size-class changes.
  Selection and preferred compact columns remain owned by the existing navigation
  model and view state.
- Keep recipe form presentation above the navigation containers. Resizing must
  preserve the active form, pending edits, and presented import/generation flow.
- Cooking uses `AnyLayout` to arrange ingredients and steps without replacing
  their view identity. Accessibility text sizes use the vertical layout. The
  cooking store owns the current step and timer independently of layout.
- Use local geometry and actual safe areas. Do not infer available space from
  an iPhone/iPad idiom, device orientation, or a global screen.
- Photo detail fits the complete image inside the available safe area. Only its
  black background extends under system chrome. The paging viewport is clipped
  so adjacent photos cannot draw under a vertical bar. A standard page-style
  `TabView` binds selection to the photo identity across viewport changes.
- Photo grids use available-width adaptation inside their navigation column.
  Do not force a global even column count without checking whether that grid
  actually spans an active fold.

Cooking content remains a continuous scrollable screen. Do not insert
`ArrangementView` inside that scroll view. A future independently scrolling
ingredients/steps design would require a separate product decision and native
fold-transition validation.

## Navigation, Bars, and Capture

- Standard `TabView`, `NavigationSplitView`, and `NavigationStack` own bar
  placement, compression, and overflow. Action labels retain both titles and
  symbols so the system can choose their presentation.
- The photo viewer's close action uses `.cancellationAction` so navigation
  dismissal has its semantic placement in either toolbar axis.
- Recipe titles use their native navigation title when `toolbarVerticalEdge`
  indicates vertical bars. Custom wrapping large titles remain limited to
  horizontal bars, where they do not overlap the sidebar control. Only the
  toolbar item changes during a resize; the screen content keeps its identity.
- Keep keyboard input attached to its safe-area bar. Do not move the recipe
  preference composer into the vertical toolbar.
- Keep standard sheet placement and native dialogs unless a specific screen
  demonstrates a need for an override.
- Camera input uses `UIImagePickerController`, with availability checked before
  presentation. Cookle does not select physical front cameras or own an
  `AVCaptureSession`; camera direction and accessory APIs are not required by
  this implementation. Actual capture across display transitions still needs
  a physical-device check.

The app already declares a generated launch screen, all four iPad orientations,
and portrait plus both landscape orientations on iPhone. It does not set
`UIRequiresFullScreen`. SwiftUI `WindowGroup` owns the scene lifecycle; the
notification app delegate only handles notification-origin bookkeeping during
scene connection.

## Regression Checklist

Use a dedicated Cookle iPhone Duo Simulator with the selected Xcode and its
compatible runtime. Existing capture mode provides isolated sample data without
altering a live store. Record actual coverage separately from this checklist.

- Open and close while a recipe, photo, search result, or Diary entry is selected.
  Check Back and reselection after each transition.
- Resize an unsaved recipe form with the keyboard visible. Verify pending text,
  cancellation confirmation, and save-action reachability.
- Page through full-screen photos, resize, and verify the same photo remains
  visible without cropping or chrome overlap. Verify Close in either bar axis.
- Change cooking steps and start a timer; verify both survive display changes.
- Check closed, open, book, laptop, and tent poses, including their transitions.
- Check both landscape directions, large Dynamic Type, Reduce Transparency,
  toolbar overflow, and both sides of Split View.
- Check camera capture on hardware. Simulator layout evidence does not establish
  camera output, simultaneous display operation, or distribution readiness.

## Verification Record

On 2026-11-10, SwiftLint formatting and the retained repository rules passed,
including 28 tooling tests. The shared library and its behavior were unchanged;
its unit suite was not rerun for this presentation-only change.

An explicit Cookle app build with Xcode 27.2 (`27B52`, selected by
`xcode-select`) succeeded with no reported warnings or errors. The current
build log confirmed compilation of the changed `PhotoDetailView.swift`.

Native verification used iPhone Duo on iOS 27.2 with isolated Japanese sample
data. An unsaved recipe name and the presented editor survived an
open-to-closed-to-open transition with the software keyboard visible. The editor
used a vertical action bar on the outer display and a horizontal bar in its
centered sheet on the inner display.

Cooking retained the selected second step and a running five-minute timer through
open, partially open, closed, and reopened states. The timer continued counting
down rather than restarting. These checks exercised existing presentation state;
they did not enable notification or Watch delivery.

The initial photo implementation exposed two failures on Duo: adjacent pages drew
under the vertical bar, and selecting the second photo before opening the device
returned the viewer to the first photo. Clipping fixed the drawing overflow;
replacing geometry-based scroll paging with a native page-style `TabView` fixed
selection retention. The final implementation passed direct opening of the second
photo, backward/forward paging, display opening and closing, and inner-display
portrait rotation while keeping the second photo selected.

The initial pass used the sample store's fallback symbol images. These
observations establish viewport boundaries and identity retention, not real-photo
quality. Laptop/tent poses, both Split View positions, large Dynamic Type, Reduce
Transparency, physical camera capture, older-OS behavior, and ordinary iPhone/iPad
regression checks were not included in that initial pass.

Simulator logs contained UIKit orientation-deprecation, unavailable-service,
CoreVideo pixel-buffer, and keyboard-coordinate diagnostics. No corresponding
crash or interaction failure was observed in the final checks, but their origins
were not established; this is not a clean-runtime-diagnostics claim. The app was
stopped and the original scheme and run destination were restored after testing.

An independent static review covered screen access, orientation and idiom
decisions, safe-area calculations, and scene lifecycle across the app and its
shared/companion sources. It found no additional required migrations. Static
review and a successful build do not establish fold-transition behavior.

### Expanded Simulator Verification

The follow-up pass on 2026-11-10 used the repository's actual sample PNGs through
`COOKLE_CAPTURE_PHOTO_DIRECTORY`. Capture data remained isolated from live stores.

At the maximum accessibility text size (`accessibility-extra-extra-extra-large`)
with Reduce Transparency enabled, recipe and cooking content remained scrollable.
Ingredients and amounts stacked vertically, cooking steps wrapped, and timer
controls remained reachable. An unsaved ingredient amount survived a display
transition with the software keyboard visible; update and cancellation controls
remained available.

The real-photo viewer retained the second photo through paging, opening and
closing, and both inner-display landscape orientations. The complete source image
remained fitted within the safe viewport without adjacent-page drawing under
the system bars.

With Cookle on either side of a two-app Split View, the photo viewer respected
the controls on the corresponding outer edge and returned to the selected recipe
through Close. The right-side editor also kept its keyboard and cancellation
action usable. The documented Home-indicator drag provided the Split View entry
point; resizing the simulated device window alone was not counted as Split View
coverage.

In right-side Split View, the Search tab's category route and Diary both supported
opening an item, going Back, and selecting the same item again. The selected Diary
entry also survived an open-to-closed-to-open transition in the same app process.
The native Simulator keyboard successfully entered a text query and displayed
matching recipes. The desktop text-insertion path had not delivered the same
input; no app-side input failure was reproduced with the native keyboard.
After an open-to-closed-to-open round trip, reopening the sidebar restored the
same query and matching results without retyping, while the selected recipe
remained selected. In detail-only presentation, the system search field had
shown a placeholder; that appearance did not mean the query state was lost.

Opening Duo with a recipe selected from text-search results exposed an overlap
between the sidebar control and the custom large title. The title modifier now
uses the system-provided vertical-bar edge to defer to the native navigation
title in that context. Horizontal bars retain the existing wrapping title.
The rebuilt app showed clear separation between the sidebar control and title
in full-width detail with a right-side vertical bar. Text-search selection and
the query also survived opening the device in the same app process.
An ordinary iPhone check of the rebuilt app retained the two-line wrapping title
with clear Back and Edit controls under a horizontal bar.
The updated app build compiled both title modifiers successfully with no reported
warnings or errors. Formatting, SwiftLint, retained repository rules, and all
28 tooling tests passed.

The native overflow menu was also reachable in the closed landscape state;
Diary's Add Recipe and Add Diary actions remained readable and available.

On the ordinary iPhone 18 Pro and 11-inch iPad Pro Simulators, the second photo
opened directly, remained selected after rotation, paged in both directions,
and closed back to the recipe. The image remained fitted within the available
safe viewport. On iPad, dragging the native window resize handle to reduce the
window and then restoring full screen also retained the second photo in the same
app process.

Native run-tool sessions terminated during some Duo checks, and the iPad run
tool reported a Simulator connection failure. Those interrupted transitions were
not counted as successful checks. Verification continued with the same built app
launched through official `simctl` commands and observed through the Simulator UI.
Owned app runs were stopped after verification. Text size, Reduce Transparency,
keyboard capture, and the original scheme and run destination were restored;
the workspace opened for this pass was closed.

### Remaining Verification Limits

- Arbitrary hinge angles and specifically named laptop/tent poses remain
  unverified. Device Hub exposed closed, partially open, and open controls, but
  the UI automation interface could not hold Option while dragging its angle
  slider.
- Device Hub's resizable mode produced a black simulated display in this run;
  it supplied no usable visual evidence. Actual two-app Split View coverage is
  recorded separately above.
- Older-OS runtime regression remains unverified because this host only had
  iOS 27.2 runtimes available for these devices.
- Physical camera capture, iPhone Mirroring, simultaneous physical displays, and
  distribution readiness require separate device or release verification.

## References

- [Preparing your app for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/)
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [AnyLayout](https://developer.apple.com/documentation/swiftui/anylayout)
- [PageTabViewStyle](https://developer.apple.com/documentation/swiftui/pagetabviewstyle)
- [Vertical toolbar edge](https://developer.apple.com/documentation/swiftui/environmentvalues/toolbarverticaledge)
- [Device Hub interactions](https://developer.apple.com/documentation/xcode/interacting-with-your-app-in-device-hub)
- [iPhone Duo multitasking](https://developer.apple.com/videos/play/tech-talks/111461/)
