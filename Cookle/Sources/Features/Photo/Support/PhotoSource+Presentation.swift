import CookleLibrary
import SwiftUI

extension PhotoSource {
    /// Localized heading shown above the photos from this source.
    ///
    /// `PhotoSource.description` stays the canonical English name in the
    /// presentation-free library. Section headings need a localized `Text`, and
    /// passing that `String` to `Text` would not localize it.
    var sectionTitle: Text {
        switch self {
        case .photosPicker:
            Text("Photos")
        case .imagePlayground:
            Text("Image Playground")
        }
    }
}
