import SwiftData
import SwiftUI

struct SettingsDataManagementSection: View {
    let model: SettingsScreenModel
    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool

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
            if isICloudEnabled {
                Text(
                    """
                    Export a backup before destructive actions. Restore and Delete All changes sync to \
                    other devices using the same iCloud account.
                    """
                )
            } else {
                Text(
                    """
                    Export a backup before destructive actions. Delete All permanently removes recipes, \
                    diaries, tags, and photos from this device.
                    """
                )
            }
        }
    }
}
