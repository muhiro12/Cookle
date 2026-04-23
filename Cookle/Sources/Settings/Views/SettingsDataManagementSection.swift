import SwiftData
import SwiftUI

struct SettingsDataManagementSection: View {
    let model: SettingsScreenModel
    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService

    var body: some View {
        Section {
            Button("Export Backup", systemImage: "square.and.arrow.up") {
                model.prepareBackupExport(
                    modelContainer: modelContainer,
                    settingsActionService: settingsActionService
                )
            }
            .disabled(model.isManageActionInProgress)
            Button("Restore Backup", systemImage: "square.and.arrow.down") {
                model.isBackupImporterPresented = true
            }
            .disabled(model.isManageActionInProgress)
            Button("Delete All", systemImage: "trash", role: .destructive) {
                model.isDeleteAllConfirmationPresented = true
            }
            .disabled(model.isManageActionInProgress)
            if model.isManageActionInProgress {
                Label {
                    Text("Working...")
                } icon: {
                    ProgressView()
                }
            }
        } header: {
            Text("Manage")
        } footer: {
            Text("Backups include recipes, diaries, tags, and linked photos. Settings and subscription status are not included.") // swiftlint:disable:this line_length
        }
    }
}
