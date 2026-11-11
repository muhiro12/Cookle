import CloudKit
import SwiftUI

struct SettingsICloudSection: View {
    @Environment(\.scenePhase)
    private var scenePhase

    @Binding var isICloudOn: Bool
    let isSubscriptionActive: Bool

    @State private var accountStatus: CKAccountStatus?

    var body: some View {
        Section {
            if isSubscriptionActive {
                Label("Subscription Active", systemImage: "checkmark.circle")
            }
            Toggle("iCloud On", isOn: $isICloudOn)
        } header: {
            Text("Settings")
        } footer: {
            Text(footer)
                .task(id: shouldCheckAccount) {
                    await refreshAccountStatus()
                }
        }
    }
}

private extension SettingsICloudSection {
    var shouldCheckAccount: Bool {
        isICloudOn && scenePhase == .active
    }

    var footer: LocalizedStringKey {
        guard isICloudOn else {
            return "Turning off iCloud sync keeps the data already on this device."
        }

        switch accountStatus {
        case .noAccount:
            return "Sign in to iCloud in the Settings app to sync across devices."
        case .available, nil:
            return "Changes may take time to appear on other devices."
        default:
            return "iCloud account status is unavailable. Your data is still on this device."
        }
    }

    func refreshAccountStatus() async {
        accountStatus = nil
        guard shouldCheckAccount else {
            return
        }

        let status = (try? await CKContainer.default().accountStatus()) ?? .couldNotDetermine
        if !Task.isCancelled {
            accountStatus = status
        }
    }
}
