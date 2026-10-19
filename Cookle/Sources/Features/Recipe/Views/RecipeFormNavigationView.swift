import SwiftUI

struct RecipeFormNavigationView: View {
    private let model: RecipeFormModel

    var body: some View {
        NavigationStack {
            RecipeFormView(model: model)
        }
        .environment(model.recipe)
    }

    init(model: RecipeFormModel) {
        self.model = model
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @State var model = RecipeFormModel(type: .create)
    RecipeFormNavigationView(model: model)
}

#Preview("Website import entry", traits: .modifier(CookleSampleData())) {
    @Previewable @State var model = RecipeFormModel(type: .create, draftSource: .website)
    RecipeFormNavigationView(model: model)
}

#Preview("Photo text import entry", traits: .modifier(CookleSampleData())) {
    @Previewable @State var model = RecipeFormModel(type: .create, draftSource: .photo)
    RecipeFormNavigationView(model: model)
}
