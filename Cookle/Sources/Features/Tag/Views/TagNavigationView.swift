import SwiftData
import SwiftUI

struct TagNavigationView<T: Tag & Identifiable>: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var tag: T?
    @Binding private var recipe: Recipe?
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $preferredCompactColumn
        ) {
            TagListView<T>(selection: $tag)
                .cookleSplitSidebar(isExpanded: horizontalSizeClass == .regular)
        } content: {
            if let tag {
                TagView<T>(
                    tagSelection: $tag,
                    recipeSelection: $recipe
                )
                .environment(tag)
            } else {
                SplitContentPlaceholder("Nothing Selected")
            }
        } detail: {
            if let recipe {
                RecipeView()
                    .environment(recipe)
            } else {
                SplitContentPlaceholder("No Recipe Selected")
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
        .recipeFormPresentationHost()
    }

    init(
        selection: Binding<T?> = .constant(nil),
        recipeSelection: Binding<Recipe?> = .constant(nil)
    ) {
        _tag = selection
        _recipe = recipeSelection
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
