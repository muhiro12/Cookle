import SwiftData
import SwiftUI

struct PhotoDetailView: View {
    @State private var currentID: Photo.ID?

    private let photos: [Photo]

    init(photos: [Photo], initialValue: Photo? = nil) {
        self.photos = photos
        self._currentID = .init(initialValue: initialValue?.id)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                LazyHStack(spacing: .zero) {
                    ForEach(photos) { photo in
                        if let image = UIImage(data: photo.data) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: geometry.size.width,
                                    height: geometry.size.height
                                )
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $currentID)
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
            ToolbarItem {
                CloseButton()
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoDetailNavigationView(photos: photos)
}
