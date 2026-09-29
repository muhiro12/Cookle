import SwiftData
import SwiftUI

struct DeleteAllConfirmationDialogModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

    func body(content: Content) -> some View {
        content
            .alert(
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
                    // Dismisses the alert.
                } label: {
                    Text("Cancel")
                }
            } message: {
                if isICloudEnabled {
                    Text(
                        """
                        This permanently deletes all recipes, diaries, tags, and photos. \
                        The deletions sync to other devices using the same iCloud account. \
                        Export your data first if you need to keep it.
                        """
                    )
                } else {
                    Text(
                        """
                        This permanently deletes all recipes, diaries, tags, and photos from this device. \
                        Export your data first if you need to keep it.
                        """
                    )
                }
            }
    }
}
