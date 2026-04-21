import AppIntents

struct DeleteCategoryIntent: AppIntent {
    static var title: LocalizedStringResource {
        "Delete Category"
    }

    @Parameter(title: "Category")
    private var value: String

    @MainActor
    func perform() -> some IntentResult & ProvidesDialog {
        let message =
            "Category deletion is currently unavailable for \(value). " +
            "Rename it or remove it from recipes instead."

        return .result(
            dialog: .init(
                stringLiteral: message
            )
        )
    }
}
