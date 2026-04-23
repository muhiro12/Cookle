import SwiftUI

@available(iOS 26.0, *)
struct RecipeIdeaSuggestionNavigationView: View {
    var body: some View {
        NavigationStack {
            RecipeIdeaSuggestionView()
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    if #available(iOS 26.0, *) {
        RecipeIdeaSuggestionNavigationView()
    }
}
