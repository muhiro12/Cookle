import SwiftUI
import SwiftUtilities

struct PhotoDetailView: View {
    private let photos: [Photo]

    init(photos: [Photo]) {
        self.photos = photos
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: .zero) {
                        ForEach(photos, id: \.self) { photo in
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
                }
                .scrollTargetBehavior(.paging)
            }
            .ignoresSafeArea(edges: .top)
            .toolbar {
                ToolbarItem {
                    CloseButton()
                }
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

#Preview {
    CooklePreview { preview in
        PhotoDetailView(photos: preview.photos)
    }
}
