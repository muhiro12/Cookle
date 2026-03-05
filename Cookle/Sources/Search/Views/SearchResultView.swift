import SwiftData
import SwiftUI

struct SearchResultView: View {
    private enum Layout {
        static let imageHeight = CGFloat(Int("240") ?? .zero)
        static let imageCornerRadius = CGFloat(Int("8") ?? .zero)
    }

    @Query private var recipes: [Recipe]

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
                        .accessibilityLabel(Text("Recipe Photo"))
                        .frame(height: Layout.imageHeight)
                        .frame(maxWidth: .infinity)
                        .clipShape(.rect(cornerRadius: Layout.imageCornerRadius))
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
