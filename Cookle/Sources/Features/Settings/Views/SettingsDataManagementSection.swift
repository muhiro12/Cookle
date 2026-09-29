import SwiftData
import SwiftUI

struct SettingsDataManagementSection: View {
    let model: SettingsScreenModel
    let modelContainer: ModelContainer
    let settingsActionService: SettingsActionService
    let isICloudEnabled: Bool
    @State private var exportRequestID: UUID?

    var body: some View {
        Section {
            Button("Export Data", systemImage: "square.and.arrow.up") {
                exportRequestID = UUID()
            }
            .disabled(isManageActionUnavailable)
            Button("Import Data", systemImage: "square.and.arrow.down") {
                model.isDataImporterPresented = true
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
                    Export your data to keep a copy you can import on any device. Export before \
                    importing or deleting, because neither can be undone. Imports and Delete All sync \
                    to other devices using the same iCloud account.
                    """
                )
            } else {
                Text(
                    """
                    Export your data to keep a copy you can import on any device. Export before \
                    importing or deleting, because neither can be undone. Delete All permanently \
                    removes recipes, diaries, tags, and photos from this device.
                    """
                )
            }
        }
        .task(id: exportRequestID) {
            await prepareRequestedExport()
        }
        .onDisappear {
            exportRequestID = nil
        }
    }
}

private extension SettingsDataManagementSection {
    var isManageActionUnavailable: Bool {
        model.isManageActionInProgress || exportRequestID != nil
    }

    func prepareRequestedExport() async {
        guard let requestID = exportRequestID else {
            return
        }
        await model.prepareDataExport(
            modelContainer: modelContainer,
            settingsActionService: settingsActionService
        )
        if exportRequestID == requestID {
            exportRequestID = nil
        }
    }
}
