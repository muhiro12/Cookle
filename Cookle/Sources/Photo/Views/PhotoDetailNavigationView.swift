import SwiftData
import SwiftUI

struct PhotoDetailNavigationView: View {
    private let photos: [Photo]
    private let initialValue: Photo?

    var body: some View {
        NavigationStack {
            PhotoDetailView(photos: photos, initialValue: initialValue)
        }
    }

    init(photos: [Photo], initialValue: Photo? = nil) {
        self.photos = photos
        self.initialValue = initialValue
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photos: [Photo]
    PhotoDetailNavigationView(photos: photos)
}
