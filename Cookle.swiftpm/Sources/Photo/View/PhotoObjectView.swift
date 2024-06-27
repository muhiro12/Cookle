import SwiftUI

struct PhotoObjectView: View {
    @Environment(PhotoObject.self) private var object

    var body: some View {
        List {
            Section("Photo") {
                if let photo = object.photo,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                }
            }
            Section("Order") {
                Text(object.order.description)
            }
            Section("Recipe") {
                Text(object.recipe?.name ?? "")
            }
            Section("Created At") {
                Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
            }
            Section("Updated At") {
                Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
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
