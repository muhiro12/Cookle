import SwiftData
import SwiftUI

struct PhotoDetailView: View {
    @State private var currentID: Photo.ID?

    private let photos: [Photo]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(photos) { photo in
                        CooklePhotoImage(
                            data: photo.data,
                            identity: .stored(photo.persistentModelID),
                            size: .detail
                        )
                        .accessibilityLabel(Text("Photo"))
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
        }
        .background(.black)
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem {
                CloseButton()
            }
        }
        .environment(\.colorScheme, .dark)
    }

    init(photos: [Photo], initialValue: Photo? = nil) {
        self.photos = photos
        self._currentID = .init(initialValue: initialValue?.id)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoDetailNavigationView(photos: photos)
}
