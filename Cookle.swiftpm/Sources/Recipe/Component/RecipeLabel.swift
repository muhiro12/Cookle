import SwiftUI

struct RecipeLabel: View {
    @Environment(Recipe.self) private var recipe

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(recipe.name)
                Text(
                    recipe.ingredientObjects.orEmpty.sorted().compactMap {
                        $0.ingredient?.value
                    }.joined(separator: ", ")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                Text(
                    recipe.categories.orEmpty.map {
                        $0.value
                    }.joined(separator: ", ")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        } icon: {
            if let photo = recipe.photoObjects?.min()?.photo,
               let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint.secondary)
            }
        }
    }
}

#Preview {
    CooklePreview { preview in
        List {
            RecipeLabel()
                .environment(preview.recipes[0])
        }
    }
}
