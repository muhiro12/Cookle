import SwiftUI

struct RecipeLabel: View {
    @Environment(Recipe.self) private var recipe

    @State private var isEditPresented = false
    @State private var isDuplicatePresented = false
    @State private var isDeletePresented = false

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
                    recipe.categories.orEmpty.map(\.value).joined(separator: ", ")
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
                    .padding()
            }
        }
        .cookleCard()
        .contextMenu {
            EditRecipeButton {
                isEditPresented = true
            }
            DuplicateRecipeButton {
                isDuplicatePresented = true
            }
            DeleteRecipeButton {
                isDeletePresented = true
            }
        }
        .confirmationDialog(
            Text("Delete \(recipe.name)"),
            isPresented: $isDeletePresented
        ) {
            Button("Delete", role: .destructive) {
                recipe.delete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
        .sheet(isPresented: $isEditPresented) {
            RecipeFormNavigationView(type: .edit)
        }
        .sheet(isPresented: $isDuplicatePresented) {
            RecipeFormNavigationView(type: .duplicate)
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
