import SwiftData
import SwiftUI

struct RecipeLabel: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.modelContext)
    private var context
    @Environment(RecipeActionService.self)
    private var recipeActionService

    @State private var isEditPresented = false
    @State private var isDuplicatePresented = false
    @State private var isDeletePresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(recipe.name)
                Text(ingredientsText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(categoriesText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        } icon: {
            if let photo = recipe.primaryPhoto,
               let image = UIImage(data: photo.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.tint.secondary)
                    .padding()
                    .accessibilityHidden(true)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
        .confirmationDialog(
            Text(RecipeDeleteCopy.title(for: recipe)),
            isPresented: $isDeletePresented
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await recipeActionService.delete(
                            context: context,
                            recipe: recipe
                        )
                    } catch {
                        errorMessage = error.localizedDescription
                        isErrorPresented = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text(RecipeDeleteCopy.message(for: recipe))
        }
        .alert(
            Text("Cannot Delete Recipe"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $isEditPresented) {
            RecipeFormNavigationView(type: .edit)
        }
        .sheet(isPresented: $isDuplicatePresented) {
            RecipeFormNavigationView(type: .duplicate)
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    List {
        RecipeLabel()
            .environment(recipes[0])
    }
}

private extension RecipeLabel {
    var ingredientsText: String {
        recipe.ingredientObjects?
            .sorted()
            .compactMap { object in
                object.ingredient?.value
            }
            .joined(separator: ", ") ?? ""
    }

    var categoriesText: String {
        recipe.categories?
            .map(\.value)
            .joined(separator: ", ") ?? ""
    }

    var accessibilitySummary: String {
        [
            "Recipe: \(recipe.name)",
            accessibilityIngredientsText,
            accessibilityCategoriesText
        ]
        .joined(separator: ". ")
    }

    var accessibilityIngredientsText: String {
        guard ingredientsText.isEmpty == false else {
            return "No ingredients"
        }

        return "Ingredients: \(ingredientsText)"
    }

    var accessibilityCategoriesText: String {
        guard categoriesText.isEmpty == false else {
            return "No categories"
        }

        return "Categories: \(categoriesText)"
    }
}
