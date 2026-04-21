import SwiftData
import SwiftUI

struct TagNavigationView<T: Tag>: View {
    @State private var tag: T?
    @State private var recipe: Recipe?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            preferredCompactColumn: $preferredCompactColumn
        ) {
            TagListView<T>(selection: $tag)
        } content: {
            if let tag {
                TagView<T>(
                    tagSelection: $tag,
                    recipeSelection: $recipe
                )
                .environment(tag)
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
        .onChange(of: tag?.persistentModelID) {
            recipe = nil
            syncPreferredCompactColumn()
        }
        .onChange(of: recipe?.persistentModelID) {
            syncPreferredCompactColumn()
        }
    }
}

private extension TagNavigationView {
    func applyInitialCompactColumnIfNeeded() {
        guard !hasAppliedInitialCompactColumn else {
            return
        }

        hasAppliedInitialCompactColumn = true
        syncPreferredCompactColumn()
    }

    func syncPreferredCompactColumn() {
        preferredCompactColumn = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: tag != nil,
            hasDetailSelection: recipe != nil
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    TagNavigationView<Ingredient>()
}
