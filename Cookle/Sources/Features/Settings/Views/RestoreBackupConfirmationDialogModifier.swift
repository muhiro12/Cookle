import SwiftData
import SwiftUI

struct RestoreBackupConfirmationDialogModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                Text("Restore Backup"),
                isPresented: $model.isRestoreConfirmationPresented
            ) {
                Button(role: .destructive) {
                    Task {
                        _ = await model.restorePendingBackup(
                            modelContainer: modelContainer,
                            settingsActionService: settingsActionService
                        )
                    }
                } label: {
                    Text("Restore")
                }
                Button(role: .cancel) {
                    model.cancelPendingRestore()
                } label: {
                    Text("Cancel")
                }
            } message: {
                Text(
                    """
                    Restoring a backup replaces all current recipes, diaries, tags, and photos. \
                    Export a backup first if you need to keep the current data.
                    """
                )
            }
    }
}
