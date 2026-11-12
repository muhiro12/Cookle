import CookleLibrary
import SwiftUI

struct SharePhotoButton: View {
    private enum Layout {
        static let previewPixelSize = 256
    }

    let data: Data

    var body: some View {
        if let image = PhotoImageProcessor.downsampledImage(
            from: data,
            maximumPixelSize: Layout.previewPixelSize
        ) {
            ShareLink(
                item: PhotoShareItem(data: data),
                preview: SharePreview("Photo", image: Image(decorative: image, scale: 1))
            ) {
                Label("Share Photo", systemImage: "square.and.arrow.up")
            }
        } else {
            Label("Cannot Share Photo", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        }
    }
}
