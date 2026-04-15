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
        case .settings:
            SettingsNavigationView()
        case .debug:
            DebugNavigationView()
        case .search:
            SearchNavigationView()
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
        case .settings:
            Label {
                Text("Settings")
            } icon: {
                Image(systemName: "gear")
            }
        case .debug:
            Label {
                Text("Debug")
            } icon: {
                Image(systemName: "flask")
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
