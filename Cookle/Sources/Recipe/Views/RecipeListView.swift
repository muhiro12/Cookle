import SwiftData
import SwiftUI
import TipKit

struct RecipeListView: View {
    private enum Layout {
        static let emptyStateSpacing = CGFloat(Int("16") ?? .zero)
    }

    @Environment(\.isPresented)
    private var isPresented

    @Query private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""

    private let addRecipeTip = AddRecipeTip()
    private let recipeDetailTip = RecipeDetailTip()

    var body: some View {
        Group {
            if recipes.isNotEmpty {
                List(selection: $recipe) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeLabel()
                                .labelStyle(.titleAndLargeIcon)
                                .environment(recipe)
                        }
                        .popoverTip(
                            currentListTip(for: recipe),
                            arrowEdge: .top
                        )
                    }
                }
                .searchable(text: $searchText)
            } else {
                VStack(spacing: Layout.emptyStateSpacing) {
                    AddRecipeButton()
                        .popoverTip(
                            addRecipeTip,
                            arrowEdge: .top
                        )
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(Text("Recipes"))
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
    var filteredRecipes: [Recipe] {
        guard searchText.isNotEmpty else {
            return recipes
        }

        return recipes.filter { recipe in
            recipe.name.normalizedContains(searchText)
        }
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
