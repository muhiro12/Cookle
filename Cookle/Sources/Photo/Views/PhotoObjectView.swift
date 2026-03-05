import SwiftData
import SwiftUI

struct PhotoObjectView: View {
    @Environment(PhotoObject.self)
    private var object

    var body: some View {
        List {
            photoSection
            orderSection
            recipeSection
            createdAtSection
            updatedAtSection
        }
    }

    var photoSection: some View {
        Section {
            if let photo = object.photo,
               let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Photo"))
            }
        } header: {
            Text("Photo")
        }
    }

    var orderSection: some View {
        Section {
            Text(object.order.description)
        } header: {
            Text("Order")
        }
    }

    var recipeSection: some View {
        Section {
            Text(object.recipe?.name ?? "")
        } header: {
            Text("Recipe")
        }
    }

    var createdAtSection: some View {
        Section {
            Text(object.createdTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Created At")
        }
    }

    var updatedAtSection: some View {
        Section {
            Text(object.modifiedTimestamp.formatted(.dateTime.year().month().day()))
        } header: {
            Text("Updated At")
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var photoObjects: [PhotoObject]
    PhotoObjectView()
        .environment(photoObjects[0])
}
