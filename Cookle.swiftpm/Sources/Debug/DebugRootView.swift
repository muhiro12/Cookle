import SwiftUI
import SwiftData

struct DebugRootView: View {
    @Environment(\.modelContext) private var context

    @AppStorage(.isICloudOn) private var isICloudOn
    @AppStorage(.isDebugOn) private var isDebugOn

    @Query(Diary.descriptor) private var diaries: [Diary]
    @Query(DiaryObject.descriptor) private var diaryObjects: [DiaryObject]
    @Query(Recipe.descriptor) private var recipes: [Recipe]
    @Query(IngredientObject.descriptor) private var ingredientObjects: [IngredientObject]
    @Query(Ingredient.descriptor) private var ingredients: [Ingredient]
    @Query(Category.descriptor) private var categories: [Category]

    @Binding private var selection: DebugContent?
    
    init(selection: Binding<DebugContent?>) {
        self._selection = selection
    }
    
    var body: some View {        
        List(selection: $selection) {
            Section {
                ForEach(DebugContent.allCases, id: \.self) { content in
                    switch content {
                    case .diary:
                        Text("Diaries")
                    case .diaryObject:
                        Text("DiaryObjects")
                    case .recipe:
                        Text("Recipes")
                    case .ingredient:
                        Text("Ingredients")
                    case .ingredientObject:
                        Text("IngredientObjects")
                    case .category:
                        Text("Categories")
                    }
                }
            }
            Section {
                Toggle("iCloud On", isOn: $isICloudOn)
                Toggle("Debug On", isOn: $isDebugOn)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Delete All", systemImage: "trash") {
                    withAnimation {
                        diaries.forEach { context.delete($0) }
                        diaryObjects.forEach { context.delete($0) }
                        recipes.forEach { context.delete($0) }
                        ingredients.forEach { context.delete($0) }
                        ingredientObjects.forEach { context.delete($0) }
                        categories.forEach { context.delete($0) }
                    }
                }
            }
            ToolbarItem {
                Button("Add Random Diary", systemImage: "dice") {
                    withAnimation {
                        _ = ModelContainerPreview { _ in
                            EmptyView()
                        }.randomDiary(context)
                    }
                }
            }
        }
    }
}

#Preview {
    DebugRootView(selection: .constant(nil))
}
