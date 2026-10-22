/// Native input arrangements used by the temporary navigation comparison.
enum RecipeGenerationInputStyle {
    case editor
    case searchTab
    case form
    case searchToolbar

    var usesSearchField: Bool {
        self == .searchTab || self == .searchToolbar
    }
}
