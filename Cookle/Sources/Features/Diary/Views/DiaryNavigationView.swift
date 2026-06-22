import SwiftData
import SwiftUI

struct DiaryNavigationView: View {
    @Binding private var diary: Diary?
    @Binding private var recipe: Recipe?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            preferredCompactColumn: $preferredCompactColumn
        ) {
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
        .task {
            applyInitialCompactColumnIfNeeded()
        }
        .onChange(of: diary?.persistentModelID) {
            recipe = nil
            syncPreferredCompactColumn()
        }
        .onChange(of: recipe?.persistentModelID) {
            syncPreferredCompactColumn()
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
    func applyInitialCompactColumnIfNeeded() {
        guard !hasAppliedInitialCompactColumn else {
            return
        }

        hasAppliedInitialCompactColumn = true
        syncPreferredCompactColumn()
    }

    func syncPreferredCompactColumn() {
        preferredCompactColumn = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: diary != nil,
            hasDetailSelection: recipe != nil
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    DiaryNavigationView()
}
