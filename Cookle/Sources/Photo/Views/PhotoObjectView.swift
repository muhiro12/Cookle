import SwiftData
import SwiftUI

struct PhotoObjectView: View {
    @Environment(PhotoObject.self) private var object

    var body: some View {
        List {
            Section {
                if let photo = object.photo,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            } header: {
                Text("Photo")
            }
            Section {
                Text(object.order.description)
            } header: {
                Text("Order")
            }
            Section {
                Text(object.recipe?.name ?? "")
            } header: {
                Text("Recipe")
            }
            Section {
                Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Created At")
            }
            Section {
                Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
            } header: {
                Text("Updated At")
            }
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photoObjects: [PhotoObject]
    PhotoObjectView()
        .environment(photoObjects[0])
}
