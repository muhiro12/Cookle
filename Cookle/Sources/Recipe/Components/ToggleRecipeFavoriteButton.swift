import SwiftData
import SwiftUI

struct ToggleRecipeFavoriteButton: View {
    @Environment(Recipe.self)
    private var recipe

    @AppStorage(\.favoriteRecipeIDs, default: "")
    private var favoriteRecipeIDs

    var body: some View {
        Button {
            toggleFavorite()
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHint(Text("Favorites appear at the top of the recipe list."))
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    ToggleRecipeFavoriteButton()
        .environment(recipes[0])
}

private extension ToggleRecipeFavoriteButton {
    var isFavorite: Bool {
        FavoriteRecipeService.isFavorite(
            recipe,
            encodedFavoriteRecipeIDs: favoriteRecipeIDs
        )
    }

    var title: String {
        isFavorite
            ? String(localized: "Remove \(recipe.name) from Favorites")
            : String(localized: "Add \(recipe.name) to Favorites")
    }

    var systemImage: String {
        isFavorite ? "star.slash" : "star"
    }

    func toggleFavorite() {
        favoriteRecipeIDs = FavoriteRecipeService.setFavorite(
            isFavorite == false,
            recipe: recipe,
            encodedFavoriteRecipeIDs: favoriteRecipeIDs
        ) ?? ""
    }
}
