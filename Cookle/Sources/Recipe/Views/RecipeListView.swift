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
                    TipView(recipeDetailTip)

                    ForEach(recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeLabel()
                                .labelStyle(.titleAndLargeIcon)
                                .environment(recipe)
                        }
                        .hidden(searchText.isNotEmpty && !recipe.name.normalizedContains(searchText))
                    }
                }
                .searchable(text: $searchText)
            } else {
                VStack(spacing: Layout.emptyStateSpacing) {
                    TipView(addRecipeTip)
                    AddRecipeButton()
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

@available(iOS 18.0, *)
#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
