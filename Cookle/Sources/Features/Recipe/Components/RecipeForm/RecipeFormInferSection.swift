import SwiftUI
import TipKit

@available(iOS 26.0, *)
struct RecipeFormInferSection: View {
    @Binding private var selection: RecipeImportSource?

    private let tip: (any Tip)?

    var body: some View {
        Section {
            ForEach(RecipeImportSource.allCases) { source in
                InferRecipeFormButton(source: source, selection: $selection)
                    .cookleButtonRowContent()
                    .cooklePopoverTip(
                        source == .text ? tip : nil,
                        arrowEdge: .top
                    )
            }
        } header: {
            Text("Import Recipe")
        } footer: {
            Text("""
            Review the text, then use Apple Intelligence to create an editable recipe draft. \
            Photos here are read for text, not attached to the recipe.
            """)
        }
    }

    init(selection: Binding<RecipeImportSource?>, tip: (any Tip)? = nil) {
        _selection = selection
        self.tip = tip
    }
}
