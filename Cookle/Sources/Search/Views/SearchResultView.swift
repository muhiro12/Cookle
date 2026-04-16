import SwiftData
import SwiftUI

struct SearchResultView: View {
    @Query private var recipes: [Recipe]

    var body: some View {
        ForEach(recipes) { recipe in
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                if let photo = recipe.primaryPhoto,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(Text("Recipe Photo"))
                        .frame(height: RecipePreviewLayout.imageHeight)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: RecipePreviewLayout.imageCornerRadius))
                }
                RecipeIngredientsSection()
                Divider()
            }
            .environment(recipe)
        }
    }

    init(_ predicate: RecipePredicate) {
        _recipes = .init(.recipes(predicate))
    }
}
