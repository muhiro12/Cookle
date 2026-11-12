import SwiftUI

private struct PhotoTransferModifier: ViewModifier {
    private enum Layout {
        static let dragPreviewSize: CGFloat = 120
    }

    let photo: Photo

    func body(content: Content) -> some View {
        content
            .draggable(PhotoShareItem(data: photo.data)) {
                CooklePhotoImage(
                    data: photo.data,
                    identity: .stored(photo.persistentModelID),
                    size: .thumbnail
                )
                .frame(width: Layout.dragPreviewSize, height: Layout.dragPreviewSize)
            }
            .contextMenu {
                SharePhotoButton(data: photo.data)
            }
    }
}

extension View {
    func photoTransfer(_ photo: Photo) -> some View {
        modifier(PhotoTransferModifier(photo: photo))
    }
}
