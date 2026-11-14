import CloudKit
import SwiftUI

struct SettingsICloudSection: View {
    @Environment(\.scenePhase)
    private var scenePhase

    @Binding var isICloudOn: Bool
    let isSubscriptionActive: Bool
    let isICloudConfigured: Bool

    @State private var accountStatus: CKAccountStatus?

    var body: some View {
        Section {
            if isSubscriptionActive {
                Label("Subscription Active", systemImage: "checkmark.circle")
            }
            Toggle("iCloud On", isOn: $isICloudOn)
                .disabled(!isSubscriptionActive && !isICloudOn)
            if isICloudConfigured {
                Text("iCloud sync is enabled for this session.")
            } else {
                Text("iCloud sync is disabled for this session.")
            }
        } header: {
            Text("Settings")
        } footer: {
            VStack(alignment: .leading) {
                Text(
                    """
                    iCloud sync requires a subscription. Your choice is saved even when your subscription ends. \
                    Changes apply after you quit and reopen Cookle.
                    """
                )
                if !isSubscriptionActive, isICloudOn {
                    Text("Your choice is on, but a subscription is required to enable iCloud sync at the next launch.")
                }
                if (isSubscriptionActive && isICloudOn) != isICloudConfigured {
                    if isICloudConfigured {
                        Text("Restart Cookle to turn off iCloud sync. It remains enabled for this session until then.")
                    } else {
                        Text("Restart Cookle to turn on iCloud sync. It remains disabled for this session until then.")
                    }
                    Text("Resuming Cookle from the background does not apply this change.")
                }
                if isICloudConfigured {
                    Text(accountGuidance)
                }
            }
            .task(id: shouldCheckAccount) {
                await refreshAccountStatus()
            }
        }
    }
}

private extension SettingsICloudSection {
    var shouldCheckAccount: Bool {
        isICloudConfigured && scenePhase == .active
    }

    var accountGuidance: LocalizedStringKey {
        switch accountStatus {
        case .noAccount:
            return "Sign in to iCloud in the Settings app to sync across devices."
        case .available, nil:
            return "Changes may take time to appear on other devices."
        default:
            return "iCloud account status is unavailable. Check your iCloud account in the Settings app."
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

#Preview("Lapsed, current iCloud session") {
    @Previewable @State var isICloudOn = true
    NavigationStack {
        List {
            SettingsICloudSection(
                isICloudOn: $isICloudOn,
                isSubscriptionActive: false,
                isICloudConfigured: true
            )
        }
        .navigationTitle("Settings")
    }
}

#Preview("Renewed, next-launch sync") {
    @Previewable @State var isICloudOn = true
    NavigationStack {
        List {
            SettingsICloudSection(
                isICloudOn: $isICloudOn,
                isSubscriptionActive: true,
                isICloudConfigured: false
            )
        }
        .navigationTitle("Settings")
    }
}

#Preview("Inactive, explicit off") {
    @Previewable @State var isICloudOn = false
    NavigationStack {
        List {
            SettingsICloudSection(
                isICloudOn: $isICloudOn,
                isSubscriptionActive: false,
                isICloudConfigured: false
            )
        }
        .navigationTitle("Settings")
    }
}
