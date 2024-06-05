import SwiftUI

struct DebugNavigationSidebarView: View {
    @Environment(\.modelContext) private var context

    @Binding private var selection: DebugContent?

    init(selection: Binding<DebugContent?>) {
        self._selection = selection
    }

    var body: some View {
        List(selection: $selection) {
            Section("Models") {
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
        }
        .toolbar {
            ToolbarItem {
                Button("Delete All", systemImage: "trash") {
                    withAnimation {
                        try! context.delete(model: Diary.self)
                        try! context.delete(model: DiaryObject.self)
                        try! context.delete(model: Recipe.self)
                        try! context.delete(model: Ingredient.self)
                        try! context.delete(model: IngredientObject.self)
                        try! context.delete(model: Category.self)
                    }
                }
            }
            ToolbarItem {
                Button("Create Preview Diary", systemImage: "flask") {
                    withAnimation {
                        _ = CooklePreviewStore().createPreviewDiary(context)
                    }
                }
            }
        }
        .navigationTitle("Debug")
    }
}

#Preview {
    DebugNavigationSidebarView(selection: .constant(nil))
}
