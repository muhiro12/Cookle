import SwiftUI

struct PhotoObjectView: View {
    @Environment(PhotoObject.self) private var object

    var body: some View {
        List {
            Section {
                if let photo = object.photo,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
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

#Preview {
    CooklePreview { preview in
        PhotoObjectView()
            .environment(preview.photoObjects[0])
    }
}
