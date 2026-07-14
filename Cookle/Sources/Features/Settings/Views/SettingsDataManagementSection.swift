import SwiftData
import SwiftUI

struct SettingsDataManagementSection: View {
    let model: SettingsScreenModel
    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool
    @State private var backupExportRequestID: UUID?

    var body: some View {
        Section {
            Button("Export Backup", systemImage: "square.and.arrow.up") {
                backupExportRequestID = UUID()
            }
            .disabled(isManageActionUnavailable)
            Button("Restore Backup", systemImage: "square.and.arrow.down") {
                model.isBackupImporterPresented = true
            }
            .disabled(isManageActionUnavailable)
            Button("Delete All", systemImage: "trash", role: .destructive) {
                model.isDeleteAllConfirmationPresented = true
            }
            .disabled(isManageActionUnavailable)
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
        .task(id: backupExportRequestID) {
            await prepareRequestedBackupExport()
        }
        .onDisappear {
            backupExportRequestID = nil
        }
    }
}

private extension SettingsDataManagementSection {
    var isManageActionUnavailable: Bool {
        model.isManageActionInProgress || backupExportRequestID != nil
    }

    func prepareRequestedBackupExport() async {
        guard let requestID = backupExportRequestID else {
            return
        }
        await model.prepareBackupExport(
            modelContainer: modelContainer,
            settingsActionService: settingsActionService
        )
        if backupExportRequestID == requestID {
            backupExportRequestID = nil
        }
    }
}
