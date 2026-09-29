import SwiftData
import SwiftUI

extension View {
    /// Presents the import flow whenever the settings model has a pending export file.
    func dataImport(
        model: SettingsScreenModel,
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService,
        isICloudEnabled: Bool
    ) -> some View {
        modifier(
            DataImportModifier(
                model: model,
                modelContainer: modelContainer,
                settingsActionService: settingsActionService,
                isICloudEnabled: isICloudEnabled
            )
        )
    }
}
