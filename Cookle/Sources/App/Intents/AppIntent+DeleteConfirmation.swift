import AppIntents

extension AppIntent {
    @MainActor
    func requestDeleteConfirmation(dialog: IntentDialog) async throws {
        let actionName = ConfirmationActionName.custom(
            acceptLabel: "Delete",
            acceptAlternatives: [],
            denyLabel: "Cancel",
            denyAlternatives: [],
            destructive: true
        )

        if #available(iOS 18.0, *) {
            try await requestConfirmation(
                conditions: [],
                actionName: actionName,
                dialog: dialog
            )
        } else {
            try await requestConfirmation(
                result: .result(dialog: dialog),
                confirmationActionName: actionName,
                showPrompt: true
            )
        }
    }
}
