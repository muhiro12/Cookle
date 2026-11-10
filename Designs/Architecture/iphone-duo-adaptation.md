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

The sample store used its fallback symbol images. These observations establish
viewport boundaries and identity retention, not real-photo quality. Laptop/tent
poses, both Split View positions, large Dynamic Type, Reduce Transparency,
physical camera capture, and older-OS runtime behavior remain outside this pass.
Ordinary iPhone and iPad runtime regression checks were also not repeated.

Simulator logs contained UIKit orientation-deprecation, unavailable-service,
CoreVideo pixel-buffer, and keyboard-coordinate diagnostics. No corresponding
crash or interaction failure was observed in the final checks, but their origins
were not established; this is not a clean-runtime-diagnostics claim. The app was
stopped and the original scheme and run destination were restored after testing.

An independent static review covered screen access, orientation and idiom
decisions, safe-area calculations, and scene lifecycle across the app and its
shared/companion sources. It found no additional required migrations. Static
review and a successful build do not establish fold-transition behavior.

## References

- [Preparing your app for iPhone Duo](https://developer.apple.com/iphone-duo/prepare/)
- [NavigationSplitView](https://developer.apple.com/documentation/swiftui/navigationsplitview)
- [AnyLayout](https://developer.apple.com/documentation/swiftui/anylayout)
- [PageTabViewStyle](https://developer.apple.com/documentation/swiftui/pagetabviewstyle)
