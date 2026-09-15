import SwiftUI

@available(iOS 26.0, *)
struct InferRecipeFormButton: View {
    let source: RecipeImportSource
    @Binding var selection: RecipeImportSource?

    var body: some View {
        Button {
            selection = source
        } label: {
            Label(source.title, systemImage: source.systemImage)
                .frame(minHeight: CookleAccessibilityLayout.minimumHitTargetSize)
                .contentShape(Rectangle())
        }
    }
}
