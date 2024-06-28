import SwiftData
import SwiftUI

struct DebugNavigationDetailView: View {
    @Query(Diary.descriptor) private var diaries: [Diary]
    @Query(DiaryObject.descriptor) private var diaryObjects: [DiaryObject]
    @Query(Recipe.descriptor) private var recipes: [Recipe]
    @Query(IngredientObject.descriptor) private var ingredientObjects: [IngredientObject]
    @Query(Ingredient.descriptor) private var ingredients: [Ingredient]
    @Query(Category.descriptor) private var categories: [Category]
    @Query(Photo.descriptor) private var photos: [Photo]
    @Query(PhotoObject.descriptor) private var photoObjects: [PhotoObject]

    private let detail: Int
    private let content: DebugContent

    init(_ detail: Int, content: DebugContent) {
        self.detail = detail
        self.content = content
    }

    var body: some View {
        Group {
            switch content {
            case .diary:
                DiaryView(selection: .constant(nil))
                    .toolbar {
                        ToolbarItem {
                            Menu("Recipes") {
                                ForEach(diaries[detail].recipes.orEmpty) {
                                    Text($0.name)
                                }
                            }
                        }
                    }
                    .environment(diaries[detail])

            case .diaryObject:
                DiaryObjectView()
                    .environment(diaryObjects[detail])

            case .recipe:
                RecipeView()
                    .environment(recipes[detail])

            case .ingredient:
                TagView<Ingredient>(selection: .constant(nil))
                    .toolbar {
                        ToolbarItem {
                            Menu("Objects") {
                                ForEach(ingredients[detail].objects.orEmpty) {
                                    Text($0.amount)
                                }
                            }
                        }
                    }
                    .environment(ingredients[detail])

            case .ingredientObject:
                IngredientObjectView()
                    .environment(ingredientObjects[detail])

            case .category:
                TagView<Category>(selection: .constant(nil))
                    .environment(categories[detail])

            case .photo:
                PhotoView(selection: .constant(nil))
                    .environment(photos[detail])

            case .photoObject:
                PhotoObjectView()
                    .environment(photoObjects[detail])
            }
        }
        .navigationTitle("Detail")
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            DebugNavigationDetailView(.zero, content: .recipe)
        }
    }
}
