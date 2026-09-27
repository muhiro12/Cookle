import SwiftData
import SwiftUI

/// Presents the merge review for a pending backup import.
struct BackupImportReviewModifier: ViewModifier {
    @Bindable var model: SettingsScreenModel

    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $model.isImportReviewPresented) {
                NavigationStack {
                    BackupImportReviewView(
                        model: model,
                        modelContainer: modelContainer,
                        settingsActionService: settingsActionService,
                        isICloudEnabled: isICloudEnabled
                    )
                }
                .id(model.pendingImport?.presentationID)
                .interactiveDismissDisabled()
            }
    }
}
