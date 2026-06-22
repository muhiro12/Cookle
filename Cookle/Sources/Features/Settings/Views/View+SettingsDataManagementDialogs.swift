import SwiftData
import SwiftUI

extension View {
    func settingsDataManagementDialogs(
        model: SettingsScreenModel,
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService
    ) -> some View {
        modifier(
            SettingsDataManagementDialogsModifier(
                model: model,
                modelContainer: modelContainer,
                settingsActionService: settingsActionService
            )
        )
    }
}
