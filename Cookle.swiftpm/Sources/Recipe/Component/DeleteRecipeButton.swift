import SwiftUI

struct DeleteRecipeButton: View {
    @Environment(Recipe.self) private var recipe

    @State private var isPresented = false

    var body: some View {
        Button("Delete \(recipe.name)", systemImage: "trash") {
            isPresented = true
        }
        .alert("Delete \(recipe.name)", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                recipe.delete()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
        .hidden() // TODO: Show
    }
}

#Preview {
    ModelContainerPreview { preview in
        DeleteRecipeButton()
            .environment(preview.recipes[0])
    }
}
