import MHUI
import SwiftData
import SwiftUI

struct SearchResultsView: View {
    @Query private var recipes: [Recipe]
    @Binding private var selection: Recipe?

    private let searchText: String
    private let onRetry: () -> Void

    var body: some View {
        if let fetchError = _recipes.fetchError {
            ContentUnavailableView {
                Label("Cannot Search Recipes", systemImage: "exclamationmark.triangle")
            } description: {
                Text(fetchError.localizedDescription)
            } actions: {
                Button("Try Again", action: onRetry)
            }
            .cookleEmptyState()
        } else if recipes.isEmpty {
            ContentUnavailableView.search(text: searchText)
                .cookleEmptyState()
        } else {
            resultList
        }
    }

    private var resultList: some View {
        List {
            MHContainerContent {
                ForEach(sortedRecipes) { recipe in
                    Button {
                        $selection.cookleSelectForNavigation(recipe)
                    } label: {
                        RecipeLabel()
                            .labelStyle(.titleAndLargeIcon)
                            .environment(recipe)
                            .cookleButtonRowContent()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mhListChrome(.content)
    }

    private var sortedRecipes: [Recipe] {
        RecipeOperations.browse(
            recipes,
            sortMode: .alphabetical,
            isAscending: true
        )
    }

    init(
        searchText: String,
        selection: Binding<Recipe?>,
        onRetry: @escaping () -> Void
    ) {
        self.searchText = searchText
        self.onRetry = onRetry
        _selection = selection
        _recipes = .init(.recipes(.anyTextMatches(searchText)))
    }
}
