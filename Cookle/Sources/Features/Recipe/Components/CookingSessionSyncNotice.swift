import MHUI
import SwiftUI

/// Shows a session started independently on the paired Watch, or a paired
/// device that needs an update before cooking can sync.
struct CookingSessionSyncNotice: View {
    @Environment(CookingSessionStore.self)
    private var cookingSessionStore
    @Environment(\.mhTheme)
    private var theme

    var body: some View {
        if let conflictingSnapshot = cookingSessionStore.conflictingSnapshot {
            VStack(alignment: .leading, spacing: theme.spacing.inline) {
                Text("Apple Watch started cooking \(conflictingSnapshot.recipeName).")
                MHActionGroup(layout: .vertical) {
                    Button("Keep This Session") {
                        cookingSessionStore.resolveConflict(
                            keepingLocalSession: true
                        )
                    }
                    Button("Switch to Apple Watch Session") {
                        cookingSessionStore.resolveConflict(
                            keepingLocalSession: false
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .mhSection("Another Cooking Session")
        }
        switch cookingSessionStore.peerStatus {
        case .compatible:
            EmptyView()
        case .peerRequiresUpdate:
            Text("Update Cookle on Apple Watch to sync cooking.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .thisDeviceRequiresUpdate:
            Text("Update Cookle on this iPhone to sync cooking.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
