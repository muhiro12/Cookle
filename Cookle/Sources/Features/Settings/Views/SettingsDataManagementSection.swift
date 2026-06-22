import SwiftData
import SwiftUI

struct SettingsDataManagementSection: View {
    let model: SettingsScreenModel

    var body: some View {
        Section {
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
            Text("Delete All permanently removes recipes, diaries, tags, and photos from this device.")
        }
    }
}
