import SwiftUI

struct RecipeFormNavigationView: View {
    private let type: RecipeFormType

    init(type: RecipeFormType) {
        self.type = type
    }

    var body: some View {
        NavigationStack {
            RecipeFormView(type: type)
        }
    }
}

#Preview {
    RecipeFormNavigationView(type: .create)
}
