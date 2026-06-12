import Foundation
import SwiftData
import SwiftUI
import TipKit

struct RecipeListView: View {
    private enum LegacyStorage {
        static let isRecipeBrowseSortAscendingKey = "C2hL9rTa"
    }

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
        \.recipeBrowseSortSelection,
        default: RecipeBrowseSortSelection.alphabeticalAscending.rawValue
    )
    private var recipeBrowseSortSelectionRawValue
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
                if !allRecipes.isEmpty {
                    ToolbarItem {
                        sortMenu
                    }
                }
                ToolbarItem {
                    AddRecipeButton()
                }
                ToolbarItem {
                    if isPresented {
                        CloseButton()
                    }
                }
            }
            .task {
                migrateLegacyRecipeBrowseSortSelectionIfNeeded()
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
        RecipeOperations.browse(
            allRecipes,
            sortMode: recipeBrowseSortSelection.sortMode,
            isAscending: recipeBrowseSortSelection.isAscending
        )
    }

    var recipeBrowseSortSelection: RecipeBrowseSortSelection {
        if let selection = RecipeBrowseSortSelection(
            rawValue: recipeBrowseSortSelectionRawValue
        ) {
            return selection
        }
        if let legacySortMode = RecipeBrowseSortMode(
            rawValue: recipeBrowseSortSelectionRawValue
        ) {
            return .init(
                sortMode: legacySortMode,
                isAscending: legacyIsRecipeBrowseSortAscending
            )
        }
        return .alphabeticalAscending
    }

    var recipeBrowseSortModeBinding: Binding<RecipeBrowseSortMode> {
        .init {
            recipeBrowseSortSelection.sortMode
        } set: { sortMode in
            recipeBrowseSortSelectionRawValue = RecipeBrowseSortSelection(
                sortMode: sortMode,
                isAscending: recipeBrowseSortSelection.isAscending
            )
            .rawValue
        }
    }

    var recipeBrowseSortAscendingBinding: Binding<Bool> {
        .init {
            recipeBrowseSortSelection.isAscending
        } set: { isAscending in
            recipeBrowseSortSelectionRawValue = RecipeBrowseSortSelection(
                sortMode: recipeBrowseSortSelection.sortMode,
                isAscending: isAscending
            )
            .rawValue
        }
    }

    var legacyIsRecipeBrowseSortAscending: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(
            forKey: LegacyStorage.isRecipeBrowseSortAscendingKey
        ) != nil else {
            return true
        }
        return defaults.bool(
            forKey: LegacyStorage.isRecipeBrowseSortAscendingKey
        )
    }

    var topReturnTarget: RecipeTopReturnTarget? {
        do {
            return try RecipeOperations.topReturnTarget(
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

            Toggle("Ascending", isOn: recipeBrowseSortAscendingBinding)
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down.circle")
        }
    }

    @ViewBuilder
    func contentView() -> some View {
        if !allRecipes.isEmpty {
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
            guard let latestTarget = try RecipeOperations.topReturnTarget(
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

    func migrateLegacyRecipeBrowseSortSelectionIfNeeded() {
        guard RecipeBrowseSortSelection(
            rawValue: recipeBrowseSortSelectionRawValue
        ) == nil else {
            return
        }
        guard let legacySortMode = RecipeBrowseSortMode(
            rawValue: recipeBrowseSortSelectionRawValue
        ) else {
            return
        }

        recipeBrowseSortSelectionRawValue = RecipeBrowseSortSelection(
            sortMode: legacySortMode,
            isAscending: legacyIsRecipeBrowseSortAscending
        )
        .rawValue
        UserDefaults.standard.removeObject(
            forKey: LegacyStorage.isRecipeBrowseSortAscendingKey
        )
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    NavigationStack {
        RecipeListView()
    }
}
