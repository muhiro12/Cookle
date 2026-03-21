import SwiftData
import SwiftUI
import TipKit

struct RecipeListView: View {
    @Environment(\.isPresented)
    private var isPresented

    @Query private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""

    private let addRecipeTip = AddRecipeTip()
    private let recipeDetailTip = RecipeDetailTip()

    var body: some View {
        contentView()
            .cookleTopLevelNavigationChrome("Recipes")
            .toolbar {
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
            ForEach(filteredRecipes) { recipe in
                recipeRow(for: recipe)
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
                .popoverTip(
                    addRecipeTip,
                    arrowEdge: .top
                )
        }
    }

    var filteredRecipes: [Recipe] {
        guard searchText.isNotEmpty else {
            return recipes
        }

        return recipes.filter { recipe in
            recipe.name.normalizedContains(searchText)
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
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .popoverTip(
            currentListTip(for: recipe),
            arrowEdge: .top
        )
    }

    func currentListTip(
        for recipe: Recipe
    ) -> (any Tip)? {
        guard searchText.isEmpty,
              filteredRecipes.first?.id == recipe.id else {
            return nil
        }

        return recipeDetailTip
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
