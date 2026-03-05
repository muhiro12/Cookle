import SwiftData
import SwiftUI

struct DebugDetailView<Model: PersistentModel>: View {
    @Environment(Model.self)
    private var model: Model

    var body: some View {
        Group {
            detailView(for: model)
        }
        .navigationTitle(Text("Detail"))
    }
}

private extension DebugDetailView {
    @ViewBuilder
    func detailView(for model: Model) -> some View {
        switch model {
        case let diary as Diary:
            DiaryView()
                .toolbar {
                    ToolbarItem {
                        Menu("Recipes") {
                            ForEach(diary.recipes.orEmpty, id: \.persistentModelID) { recipe in
                                Text(recipe.name)
                            }
                        }
                    }
                }
        case _ as DiaryObject:
            DiaryObjectView()
        case _ as Recipe:
            RecipeView()
        case let ingredient as Ingredient:
            TagView<Ingredient>()
                .toolbar {
                    ToolbarItem {
                        Menu("Objects") {
                            ForEach(ingredient.objects, id: \.persistentModelID) { object in
                                Text(object.amount)
                            }
                        }
                    }
                }
        case _ as IngredientObject:
            IngredientObjectView()
        case _ as Category:
            TagView<Category>()
        case _ as Photo:
            PhotoView()
        case _ as PhotoObject:
            PhotoObjectView()
        default:
            EmptyView()
        }
    }
}

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    NavigationStack {
        DebugDetailView<Recipe>()
            .environment(recipes[0])
    }
}
