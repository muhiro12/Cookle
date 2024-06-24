import SwiftData
import SwiftUI

struct DebugNavigationContentView: View {
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
                    Text(diaries[$0].date.formatted(.dateTime.year().month().day()))

                case .diaryObject:
                    Text(diaryObjects[$0].type?.title ?? "")

                case .recipe:
                    Text(recipes[$0].name)

                case .ingredient:
                    Text(ingredients[$0].value)

                case .ingredientObject:
                    Text((ingredientObjects[$0].ingredient?.value ?? "") + " " + ingredientObjects[$0].amount)

                case .category:
                    Text(categories[$0].value)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    indexSet.forEach { index in
                        switch content {
                        case .diary:
                            diaries[index].delete()

                        case .diaryObject:
                            diaryObjects[index].delete()

                        case .recipe:
                            recipes[index].delete()

                        case .ingredient:
                            ingredients[index].delete()

                        case .ingredientObject:
                            ingredientObjects[index].delete()

                        case .category:
                            categories[index].delete()
                        }
                    }
                }
            }
        }
        .navigationTitle("Content")
    }
}

#Preview {
    CooklePreview { _ in
        DebugNavigationContentView(.recipe, selection: .constant(nil))
    }
}
