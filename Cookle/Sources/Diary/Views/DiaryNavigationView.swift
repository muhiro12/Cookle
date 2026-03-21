import SwiftData
import SwiftUI

struct DiaryNavigationView: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var diary: Diary?
    @Binding private var recipe: Recipe?

    var body: some View {
        navigationView()
            .onChange(of: diary?.persistentModelID) {
                recipe = nil
            }
    }

    init(
        selection: Binding<Diary?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil)
    ) {
        _diary = selection
        _recipe = recipeSelection
    }
}

private extension DiaryNavigationView {
    var regularNavigationView: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            DiaryListView(selection: $diary)
        } content: {
            if let diary {
                DiaryView(selection: $recipe)
                    .environment(diary)
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            }
        }
    }

    var compactNavigationView: some View {
        NavigationStack {
            DiaryListView(selection: $diary)
                .listStyle(.insetGrouped)
                .navigationDestination(isPresented: $diary.isPresent()) {
                    if let diary {
                        DiaryView(selection: $recipe)
                            .environment(diary)
                    }
                }
                .navigationDestination(isPresented: $recipe.isPresent()) {
                    if let recipe {
                        RecipeView()
                            .environment(recipe)
                    }
                }
        }
    }

    @ViewBuilder
    func navigationView() -> some View {
        if horizontalSizeClass == .regular {
            regularNavigationView
        } else {
            compactNavigationView
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DiaryNavigationView()
}
