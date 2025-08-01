import SwiftData
import SwiftUI

struct SearchResultView: View {
    @Query private var recipes: [Recipe]

    init(_ predicate: RecipePredicate) {
        _recipes = .init(.recipes(predicate))
    }

    var body: some View {
        ForEach(recipes) { recipe in
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.headline)
                if let photo = recipe.photoObjects?.min()?.photo,
                   let image = UIImage(data: photo.data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: 8))
                }
                RecipeIngredientsSection()
                Divider()
            }
            .environment(recipe)
        }
    }
}
