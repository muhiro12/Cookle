import AppIntents

struct DeleteIngredientIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Ingredient"
    }

    @Parameter(title: "Ingredient")
    private var value: String

    @MainActor
    func perform() -> some IntentResult & ProvidesDialog {
        let message =
            "Ingredient deletion is currently unavailable for \(value). " +
            "Rename it or remove it from recipes instead."

        return .result(
            dialog: .init(
                stringLiteral: message
            )
        )
    }
}
