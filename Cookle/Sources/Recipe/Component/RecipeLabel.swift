import SwiftUI

struct RecipeLabel: View {
    @Environment(RecipeEntity.self) private var recipe
    @Environment(\.modelContext) private var context

    @State private var isEditPresented = false
    @State private var isDuplicatePresented = false
    @State private var isDeletePresented = false

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(recipe.name)
                Text(
                    recipe.ingredients.map(\.ingredient).joined(separator: ", ")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                Text(
                    recipe.categories.joined(separator: ", ")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        } icon: {
            if let data = recipe.photos.first,
               let image = UIImage(data: data) {
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
                if let model = try? recipe.model(context: context) {
                    model.delete()
                }
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
