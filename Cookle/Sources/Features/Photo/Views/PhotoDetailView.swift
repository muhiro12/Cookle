import SwiftData
import SwiftUI

struct PhotoDetailView: View {
    @State private var currentID: Photo.ID?

    private let photos: [Photo]

    var body: some View {
        TabView(selection: $currentID) {
            ForEach(photos) { photo in
                CooklePhotoImage(
                    data: photo.data,
                    identity: .stored(photo.persistentModelID),
                    size: .detail,
                    roundsCorners: false
                )
                .accessibilityLabel(Text("Photo"))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .photoTransfer(photo)
                .tag(photo.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .clipped()
        .background {
            Color.black.ignoresSafeArea()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                CloseButton()
            }
            ToolbarItem(placement: .primaryAction) {
                if let photo = photos.first(where: { $0.id == currentID }) {
                    SharePhotoButton(data: photo.data)
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }

    init(photos: [Photo], initialValue: Photo? = nil) {
        self.photos = photos
        self._currentID = .init(initialValue: initialValue?.id ?? photos.first?.id)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoDetailNavigationView(photos: photos)
}
