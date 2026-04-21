import SwiftData
import SwiftUI
import TipKit

struct RecipeListView: View {
    private struct CookingPresentation: Identifiable {
        let id = UUID()
    }

    @Environment(\.isPresented)
    private var isPresented
    @Environment(\.modelContext)
    private var context

    @Query(.recipes(.all))
    private var allRecipes: [Recipe]

    @Binding private var recipe: Recipe?

    @State private var sortMode = RecipeBrowseSortMode.alphabetical
    @State private var isAscending = true
    @State private var cookingPresentation: CookingPresentation?

    private let addRecipeTip = AddRecipeTip()

    var body: some View {
        contentView()
            .cookleTopLevelNavigationChrome("Recipes")
            .fullScreenCover(item: $cookingPresentation) { _ in
                NavigationStack {
                    CookingSessionView()
                }
            }
            .toolbar {
                if allRecipes.isNotEmpty {
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

    init(selection: Binding<Recipe?> = .constant(nil)) {
        _recipe = selection
    }
}

private extension RecipeListView {
    var recipeListView: some View {
        List {
            if let topReturnTarget {
                Section {
                    RecipeTopReturnButton(
                        target: topReturnTarget
                    ) {
                        handleTopReturnTap()
                    }
                }
            }

            ForEach(sortedRecipes) { recipe in
                recipeRow(for: recipe)
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

    var sortedRecipes: [Recipe] {
        RecipeService.browse(
            allRecipes,
            sortMode: sortMode,
            isAscending: isAscending
        )
    }

    var topReturnTarget: RecipeTopReturnTarget? {
        do {
            return try RecipeTopReturnTargetService.target(
                context: context
            )
        } catch {
            return nil
        }
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

    @ViewBuilder
    func contentView() -> some View {
        if allRecipes.isNotEmpty {
            recipeListView
        } else {
            emptyStateView
        }
    }

    func recipeRow(for recipe: Recipe) -> some View {
        Button {
            selectRecipeForNavigation(
                recipe
            )
        } label: {
            RecipeLabel()
                .labelStyle(.titleAndLargeIcon)
                .environment(recipe)
                .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
    }

    func handleTopReturnTap() {
        do {
            guard let latestTarget = try RecipeTopReturnTargetService.target(
                context: context
            ) else {
                return
            }

            switch latestTarget.kind {
            case .activeCookingSession:
                if let resolvedRecipe = try resolvedRecipe(
                    for: latestTarget
                ) {
                    selectRecipeForNavigation(
                        resolvedRecipe
                    )
                }
                cookingPresentation = .init()
            case .lastOpenedRecipe:
                guard let resolvedRecipe = try resolvedRecipe(
                    for: latestTarget
                ) else {
                    return
                }
                selectRecipeForNavigation(
                    resolvedRecipe
                )
            }
        } catch {
            // Ignore stale targets and keep the list stable.
        }
    }

    func resolvedRecipe(
        for target: RecipeTopReturnTarget
    ) throws -> Recipe? {
        try RecipeStableIdentifierCodec.recipe(
            from: target.recipeStableIdentifier,
            context: context
        )
    }

    func selectRecipeForNavigation(
        _ resolvedRecipe: Recipe
    ) {
        guard recipe?.persistentModelID == resolvedRecipe.persistentModelID else {
            recipe = resolvedRecipe
            return
        }

        recipe = nil
        Task { @MainActor in
            recipe = resolvedRecipe
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
