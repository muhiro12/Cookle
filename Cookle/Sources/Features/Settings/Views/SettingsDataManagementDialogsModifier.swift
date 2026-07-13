import SwiftData
import SwiftUI

struct SettingsDataManagementDialogsModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

    func body(content: Content) -> some View {
        content
            .modifier(
                BackupFileTransferModifier(
                    model: model,
                    settingsActionService: settingsActionService
                )
            )
            .modifier(
                RestoreBackupConfirmationDialogModifier(
                    model: model,
                    modelContainer: modelContainer,
                    settingsActionService: settingsActionService,
                    isICloudEnabled: isICloudEnabled
                )
            )
            .modifier(
                DeleteAllConfirmationDialogModifier(
                    model: model,
                    modelContainer: modelContainer,
                    settingsActionService: settingsActionService,
                    isICloudEnabled: isICloudEnabled
                )
            )
            .modifier(
                SettingsActionStatusAlertModifier(
                    model: model
                )
            )
    }
}
