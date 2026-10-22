/// Native input arrangements used by the temporary navigation comparison.
enum RecipeGenerationInputStyle {
    case editor
    case bottomComposer
    case form

    var usesEmbeddedSubmit: Bool {
        self == .bottomComposer
    }
}
