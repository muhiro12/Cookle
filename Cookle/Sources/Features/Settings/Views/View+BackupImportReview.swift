import SwiftData
import SwiftUI

extension View {
    /// Presents the merge review whenever the settings model has a pending backup import.
    func backupImportReview(
        model: SettingsScreenModel,
        modelContainer: ModelContainer,
        settingsActionService: SettingsActionService,
        isICloudEnabled: Bool
    ) -> some View {
        modifier(
            BackupImportReviewModifier(
                model: model,
                modelContainer: modelContainer,
                settingsActionService: settingsActionService,
                isICloudEnabled: isICloudEnabled
            )
        )
    }
}
