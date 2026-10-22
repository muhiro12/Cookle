import SwiftUI

extension MainTab {
    @ViewBuilder var rootView: some View {
        switch self {
        case .diary:
            DiaryNavigationView()
        case .recipe:
            RecipeNavigationView()
        case .photo:
            PhotoNavigationView()
        case .search:
            SearchNavigationView()
        case .aiRecipe:
            AIRecipeNavigationView()
        }
    }

    @ViewBuilder var label: some View {
        switch self {
        case .diary:
            Label {
                Text("Diary")
            } icon: {
                Image(systemName: "book")
            }
        case .recipe:
            Label {
                Text("Recipe")
            } icon: {
                Image(systemName: "book.pages")
            }
        case .photo:
            Label {
                Text("Photo")
            } icon: {
                Image(systemName: "photo.stack")
            }
        case .aiRecipe:
            Label {
                Text("AI")
            } icon: {
                Image(systemName: "sparkles")
            }
        case .search:
            Label {
                Text("Search")
            } icon: {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}
