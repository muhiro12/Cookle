import SwiftData
import SwiftUI
import TipKit

struct RecipeListView: View {
    private enum FilterSheet: String, Identifiable {
        case category
        case ingredient

        var id: Self {
            self
        }
    }

    @Environment(\.isPresented)
    private var isPresented

    @Query private var recipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var searchText = ""
    @State private var sortMode = RecipeBrowseSortMode.alphabetical
    @State private var isAscending = true
    @State private var selectedCategory: Category?
    @State private var selectedIngredient: Ingredient?
    @State private var photosOnly = false
    @State private var filterSheet: FilterSheet?

    private let addRecipeTip = AddRecipeTip()

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
            browseControlsSection
            if filteredRecipes.isNotEmpty {
                ForEach(filteredRecipes) { recipe in
                    recipeRow(for: recipe)
                }
            } else {
                filteredEmptyStateSection
            }
        }
        .searchable(text: $searchText)
        .sheet(item: $filterSheet) { sheet in
            NavigationStack {
                switch sheet {
                case .category:
                    TagListView<Category>(
                        selection: categorySelectionBinding
                    )
                    .listStyle(.insetGrouped)
                case .ingredient:
                    TagListView<Ingredient>(
                        selection: ingredientSelectionBinding
                    )
                    .listStyle(.insetGrouped)
                }
            }
        }
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
                selectedCategory: selectedCategory,
                selectedIngredient: selectedIngredient,
                photosOnly: photosOnly,
                sortMode: sortMode,
                isAscending: isAscending
            )
        )
    }

    var browseControlsSection: some View {
        Section("Sort & Filter") {
            Picker("Sort", selection: $sortMode) {
                ForEach(RecipeBrowseSortMode.allCases) { sortMode in
                    Text(sortMode.title)
                        .tag(sortMode)
                }
            }
            .pickerStyle(.menu)

            Toggle("Ascending", isOn: $isAscending)
            Toggle("With Photos Only", isOn: $photosOnly)
            categoryFilterButton
            ingredientFilterButton

            if hasActiveFilters {
                Button("Clear Filters") {
                    clearFilters()
                }
            }
        }
    }

    var filteredEmptyStateSection: some View {
        Section {
            if hasActiveFilters {
                ContentUnavailableView {
                    Label("No Matching Recipes", systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text("Try a different search or clear filters.")
                } actions: {
                    Button("Clear Filters") {
                        clearFilters()
                    }
                }
            } else {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    var hasActiveFilters: Bool {
        selectedCategory != nil || selectedIngredient != nil || photosOnly
    }

    var categorySelectionBinding: Binding<Category?> {
        .init(
            get: {
                selectedCategory
            },
            set: { selectedCategory in
                self.selectedCategory = selectedCategory
                filterSheet = nil
            }
        )
    }

    var ingredientSelectionBinding: Binding<Ingredient?> {
        .init(
            get: {
                selectedIngredient
            },
            set: { selectedIngredient in
                self.selectedIngredient = selectedIngredient
                filterSheet = nil
            }
        )
    }

    var categoryFilterButton: some View {
        Button {
            filterSheet = .category
        } label: {
            selectionRow(
                title: "Category",
                value: selectedCategory?.value ?? "Any Category"
            )
        }
        .buttonStyle(.plain)
    }

    var ingredientFilterButton: some View {
        Button {
            filterSheet = .ingredient
        } label: {
            selectionRow(
                title: "Ingredient",
                value: selectedIngredient?.value ?? "Any Ingredient"
            )
        }
        .buttonStyle(.plain)
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
    }

    @ViewBuilder
    func selectionRow(
        title: LocalizedStringKey,
        value: String
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    func clearFilters() {
        selectedCategory = nil
        selectedIngredient = nil
        photosOnly = false
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
