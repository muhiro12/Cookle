import SwiftUI

struct RecipeFormNavigationView: View {
    private let initialImportSource: RecipeImportSource?
    private let type: RecipeFormType

    var body: some View {
        NavigationStack {
            RecipeFormView(type: type, initialImportSource: initialImportSource)
        }
    }

    init(type: RecipeFormType, initialImportSource: RecipeImportSource? = nil) {
        self.initialImportSource = initialImportSource
        self.type = type
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    RecipeFormNavigationView(type: .create)
}

#Preview("Website import entry", traits: .modifier(CookleSampleData())) {
    RecipeFormNavigationView(type: .create, initialImportSource: .website)
}

#Preview("Photo text import entry", traits: .modifier(CookleSampleData())) {
    RecipeFormNavigationView(type: .create, initialImportSource: .photo)
}
