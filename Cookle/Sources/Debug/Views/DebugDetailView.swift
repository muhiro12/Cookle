import SwiftData
import SwiftUI

struct DebugDetailView<Model: PersistentModel>: View {
    @Environment(Model.self) private var model: Model

    var body: some View {
        Group {
            switch model {
            case let diary as Diary:
                DiaryView()
                    .toolbar {
                        ToolbarItem {
                            Menu("Recipes") {
                                ForEach(diary.recipes.orEmpty) {
                                    Text($0.name)
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
                                ForEach(ingredient.objects.orEmpty) {
                                    Text($0.amount)
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
        .navigationTitle(Text("Detail"))
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
