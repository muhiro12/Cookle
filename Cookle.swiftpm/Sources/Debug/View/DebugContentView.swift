import SwiftUI
import SwiftData

struct DebugContentView: View {
    @Environment(\.modelContext) private var context

    @Binding private var selection: Int?

    @Query(Diary.descriptor) private var diaries: [Diary]
    @Query(DiaryObject.descriptor) private var diaryObjects: [DiaryObject]
    @Query(Recipe.descriptor) private var recipes: [Recipe]
    @Query(IngredientObject.descriptor) private var ingredientObjects: [IngredientObject]
    @Query(Ingredient.descriptor) private var ingredients: [Ingredient]
    @Query(Category.descriptor) private var categories: [Category]

    private let content: DebugContent

    init(_ content: DebugContent, selection: Binding<Int?>) {
        self.content = content
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(
                0..<{
                    switch content {
                    case .diary:
                        diaries.endIndex
                    case .diaryObject:
                        diaryObjects.endIndex
                    case .recipe:
                        recipes.endIndex
                    case .ingredient:
                        ingredients.endIndex
                    case .ingredientObject:
                        ingredientObjects.endIndex
                    case .category:
                        categories.endIndex
                    }
                }(),
                id: \.self
            ) {
                switch content {
                case .diary:
                    Text(diaries[$0].date.formatted())
                case .diaryObject:
                    Text(diaryObjects[$0].type.debugDescription)
                case .recipe:
                    Text(recipes[$0].name)
                case .ingredient:
                    Text(ingredients[$0].value)
                case .ingredientObject:
                    Text(ingredientObjects[$0].ingredient.value + " " + ingredientObjects[$0].amount)
                case .category:
                    Text(categories[$0].value)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    indexSet.forEach { index in
                        switch content {
                        case .diary:
                            context.delete(diaries[index])
                        case .diaryObject:
                            context.delete(diaryObjects[index])
                        case .recipe:
                            context.delete(recipes[index])
                        case .ingredient:
                            context.delete(ingredients[index])
                        case .ingredientObject:
                            context.delete(ingredientObjects[index])
                        case .category:
                            context.delete(categories[index])
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ModelContainerPreview { _ in
        DebugContentView(.recipe, selection: .constant(nil))
    }
}
