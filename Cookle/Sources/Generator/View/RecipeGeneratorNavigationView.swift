import SwiftUI

struct RecipeGeneratorNavigationView: View {
    var body: some View {
        NavigationStack {
            RecipeGeneratorView()
        }
    }
}

#Preview {
    CooklePreview { _ in
        RecipeGeneratorNavigationView()
    }
}
