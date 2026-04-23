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

    @AppStorage(
        \.recipeBrowseSortMode,
        default: RecipeBrowseSortMode.alphabetical.rawValue
    )
    private var recipeBrowseSortModeRawValue
    @AppStorage(\.isRecipeBrowseSortAscending)
    private var isRecipeBrowseSortAscending
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
            sortMode: recipeBrowseSortMode,
            isAscending: isRecipeBrowseSortAscending
        )
    }

    var recipeBrowseSortMode: RecipeBrowseSortMode {
        RecipeBrowseSortMode(rawValue: recipeBrowseSortModeRawValue)
            ?? .alphabetical
    }

    var recipeBrowseSortModeBinding: Binding<RecipeBrowseSortMode> {
        .init {
            recipeBrowseSortMode
        } set: { sortMode in
            recipeBrowseSortModeRawValue = sortMode.rawValue
        }
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
            Picker("Sort", selection: recipeBrowseSortModeBinding) {
                ForEach(RecipeBrowseSortMode.allCases) { sortMode in
                    Text(sortMode.title)
                        .tag(sortMode)
                }
            }
            .pickerStyle(.menu)

            Toggle("Ascending", isOn: $isRecipeBrowseSortAscending)
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

    func recipeRow(for rowRecipe: Recipe) -> some View {
        Button {
            $recipe.cookleSelectForNavigation(
                rowRecipe
            )
        } label: {
            RecipeLabel()
                .labelStyle(.titleAndLargeIcon)
                .environment(rowRecipe)
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
                    $recipe.cookleSelectForNavigation(
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
                $recipe.cookleSelectForNavigation(
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
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
