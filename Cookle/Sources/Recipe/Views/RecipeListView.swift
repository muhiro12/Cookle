import SwiftData
import SwiftUI
import TipKit

struct RecipeListView: View {
    @Environment(\.isPresented)
    private var isPresented

    @Query private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""
    @State private var sortMode = RecipeBrowseSortMode.alphabetical
    @State private var isAscending = true

    private let addRecipeTip = AddRecipeTip()

    var body: some View {
        contentView()
            .cookleTopLevelNavigationChrome("Recipes")
            .toolbar {
                if recipes.isNotEmpty {
                    ToolbarItem {
                        sortMenu
                    }
                }
                ToolbarItem {
                    AddRecipeButton()
                }
                ToolbarItem {
                    CloseButton()
                        .hidden(!isPresented)
                }
            }
    }

    init(selection: Binding<Recipe?> = .constant(nil), descriptor: FetchDescriptor<Recipe> = .recipes(.all)) {
        _recipe = selection
        _recipes = .init(descriptor)
    }
}

private extension RecipeListView {
    var recipeListView: some View {
        List {
            if filteredRecipes.isNotEmpty {
                ForEach(filteredRecipes) { recipe in
                    recipeRow(for: recipe)
                }
            } else {
                filteredEmptyStateSection
            }
        }
        .searchable(text: $searchText)
    }

    var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Recipes Yet", systemImage: "book.pages")
        } description: {
            Text("Add a recipe to start building your collection.")
        } actions: {
            AddRecipeButton()
                .cooklePopoverTip(
                    addRecipeTip,
                    arrowEdge: .top
                )
        }
    }

    var filteredRecipes: [Recipe] {
        RecipeBrowseResults.recipes(
            from: recipes,
            criteria: .init(
                searchText: searchText,
                sortMode: sortMode,
                isAscending: isAscending
            )
        )
    }

    var sortMenu: some View {
        Menu {
            Picker("Sort", selection: $sortMode) {
                ForEach(RecipeBrowseSortMode.allCases) { sortMode in
                    Text(sortMode.title)
                        .tag(sortMode)
                }
            }
            .pickerStyle(.menu)

            Toggle("Ascending", isOn: $isAscending)
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down.circle")
        }
    }

    var filteredEmptyStateSection: some View {
        Section {
            ContentUnavailableView.search(text: searchText)
        }
    }

    @ViewBuilder
    func contentView() -> some View {
        if recipes.isNotEmpty {
            recipeListView
        } else {
            emptyStateView
        }
    }

    func recipeRow(for recipe: Recipe) -> some View {
        Button {
            self.recipe = recipe
        } label: {
            RecipeLabel()
                .labelStyle(.titleAndLargeIcon)
                .environment(recipe)
                .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
