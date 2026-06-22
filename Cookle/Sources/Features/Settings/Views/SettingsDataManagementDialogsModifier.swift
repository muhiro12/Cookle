import SwiftData
import SwiftUI

struct SettingsDataManagementDialogsModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService

    func body(content: Content) -> some View {
        content
            .modifier(
                DeleteAllConfirmationDialogModifier(
                    model: model,
                    modelContainer: modelContainer,
                    settingsActionService: settingsActionService
                )
            )
            .modifier(
                SettingsActionStatusAlertModifier(
                    model: model
                )
            )
    }
}
