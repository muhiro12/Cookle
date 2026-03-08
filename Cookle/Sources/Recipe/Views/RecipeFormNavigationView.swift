import SwiftUI

struct RecipeFormNavigationView: View {
    private let type: RecipeFormType

    var body: some View {
        NavigationStack {
            RecipeFormView(type: type)
        }
    }

    init(type: RecipeFormType) {
        self.type = type
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    RecipeFormNavigationView(type: .create)
}
