import SwiftData
import SwiftUI

struct DeleteAllConfirmationDialogModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                Text("Delete All"),
                isPresented: $model.isDeleteAllConfirmationPresented
            ) {
                Button(role: .destructive) {
                    Task {
                        _ = await model.deleteAllData(
                            modelContainer: modelContainer,
                            settingsActionService: settingsActionService
                        )
                    }
                } label: {
                    Text("Delete")
                }
                Button(role: .cancel) {
                    // Dismisses the confirmation dialog.
                } label: {
                    Text("Cancel")
                }
            } message: {
                Text("This permanently deletes all recipes, diaries, tags, and photos from this device.")
            }
    }
}
