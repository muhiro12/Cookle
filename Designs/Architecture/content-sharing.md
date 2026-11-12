# Content sharing

## Selected journeys

[Issue #151](https://github.com/muhiro12/Cookle/issues/151) asks for a small set
of useful native transfers. The selected addition is sending one displayed
photo to another app, through either Share Photo or a drag. A person can send
a dish picture without exporting the library or sending its recipe text.

Share Photo is available in the photo information screen and the full-screen
photo viewer. The photo collection, recipe photo strip, information preview,
and full-screen image also offer a context menu and a drag source. Swiping the
full-screen viewer changes which photo its toolbar shares. Normal tap navigation
and the visible share action remain available without dragging.

## Existing operations

| Journey | Existing path |
| --- | --- |
| Readable recipe content | Copy Recipe Content and Share Recipe Content |
| Reference to an existing recipe | Share Recipe Link using the existing URL builder |
| Portable library data | Existing `.cookle` export and reviewed import |
| Create a recipe from outside text or photos | Existing text/OCR assistance and unsaved recipe form |

Readable content follows [recipe text workflows](recipe-text-workflows.md).
Sharing a recipe link does not transfer its stored recipe or photo data.

## Photo representation

`PhotoShareItem` captures image bytes as a value, without holding a SwiftData
record across the system's deferred transfer. Native `ShareLink` and `draggable`
use the same export-only PNG `DataRepresentation`, named `Cookle-Photo.png`.
There is no new custom UTI or inbound Cookle payload.

`PhotoImageProcessor.sharePNGData` produces a still image from the first frame,
applies orientation, preserves transparency, and limits the longest edge to
the existing stored-photo bound of 2,048 pixels. Re-encoding decoded pixels
omits source metadata, including location and camera information. Recipe names,
other photos, notes, diary history, identifiers, and source URLs are not included.
Visible text or people within the photo remain part of its pixels.

An unreadable photo shows Cannot Share Photo in place of the share action.
If deferred drag encoding fails, it throws instead of forwarding original bytes.
Exporting or cancelling a share never changes the stored photo, its links, or
recipe and diary data. Original-byte portability remains the existing library
export's responsibility.

## Deferred candidates

Recipe-to-diary drops would need a demonstrated advantage over existing selection
and Add to Today actions, while retaining meal selection and review. Incoming
image/text/file drops would add entry points to existing review workflows;
they are not needed to complete this outgoing-photo journey. Recipe-link dragging
is also deferred: readable content sharing already serves recipients who do not
have the original record. No new Share Extension is introduced.

## Verification boundary

Library tests verify the image content type, dimensions, source orientation,
transparency, metadata omission, and invalid-input refusal. Consumer builds cover
the native transfer adapter. Runtime verification must cover photo selection,
share-sheet presentation/cancellation, and iPad drag behavior without breaking
tap navigation or paging. Recipient apps decide their supported drop targets;
a successful share-sheet presentation alone does not prove delivery.

## Platform references

- [ShareLink](https://developer.apple.com/documentation/swiftui/sharelink)
- [DataRepresentation](https://developer.apple.com/documentation/coretransferable/datarepresentation)
