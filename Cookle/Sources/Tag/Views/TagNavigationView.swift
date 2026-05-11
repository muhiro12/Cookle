import SwiftData
import SwiftUI

struct TagNavigationView<T: Tag & Identifiable>: View {
    @Environment(\.horizontalSizeClass)
    private var horizontalSizeClass

    @Binding private var tag: T?
    @Binding private var recipe: Recipe?
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    @State private var hasAppliedInitialCompactColumn = false

    var body: some View {
        if horizontalSizeClass == .compact {
            compactNavigationStack
        } else {
            splitNavigationView
        }
    }

    var compactNavigationStack: some View {
        NavigationStack {
            TagListView<T>(selection: $tag)
                .navigationDestination(item: $tag) { selectedTag in
                    TagView<T>(
                        tagSelection: $tag,
                        recipeSelection: $recipe
                    )
                    .environment(selectedTag)
                }
                .navigationDestination(item: $recipe) { selectedRecipe in
                    RecipeView()
                        .environment(selectedRecipe)
                }
        }
    }

    var splitNavigationView: some View {
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
