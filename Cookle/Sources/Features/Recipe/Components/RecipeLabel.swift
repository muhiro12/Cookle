import MHUI
import SwiftData
import SwiftUI

struct RecipeLabel: View {
    @Environment(Recipe.self)
    private var recipe

    @State private var deletionReview: RecipeDeletionReview?

    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .mhRowTitle()
                Text(ingredientsText)
                    .mhRowSupporting()
                    .lineLimit(1)
                Text(categoriesText)
                    .mhRowSupporting()
                    .lineLimit(1)
            }
        } icon: {
            if let photo = recipe.primaryPhoto {
                CooklePhotoImage(
                    data: photo.data,
                    identity: .stored(photo.persistentModelID),
                    size: .thumbnail
                )
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
            EditRecipeButton()
            DuplicateRecipeButton()
            DeleteRecipeButton { review in
                deletionReview = review
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilitySummary))
        .recipeDeletionReview($deletionReview)
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
            String(localized: "Recipe: \(recipe.name)"),
            accessibilityIngredientsText,
            accessibilityCategoriesText
        ]
        .joined(separator: ". ")
    }

    var accessibilityIngredientsText: String {
        guard ingredientsText.isEmpty == false else {
            return String(localized: "No ingredients")
        }

        return String(localized: "Ingredients: \(ingredientsText)")
    }

    var accessibilityCategoriesText: String {
        guard categoriesText.isEmpty == false else {
            return String(localized: "No categories")
        }

        return String(localized: "Categories: \(categoriesText)")
    }
}
