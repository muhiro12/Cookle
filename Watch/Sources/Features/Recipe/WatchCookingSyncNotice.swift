import SwiftUI

/// Shows a session started independently on iPhone, or a paired device that
/// needs an update before cooking can sync.
struct WatchCookingSyncNotice: View {
    @EnvironmentObject private var cookingSessionStore: WatchCookingSessionStore

    var body: some View {
        if let conflictingSnapshot = cookingSessionStore.conflictingSnapshot {
            VStack(alignment: .leading) {
                Text("iPhone started cooking \(conflictingSnapshot.recipeName).")
                    .font(.footnote)
                Button("Keep This Session") {
                    cookingSessionStore.resolveConflict(
                        keepingLocalSession: true
                    )
                }
                Button("Switch to iPhone Session") {
                    cookingSessionStore.resolveConflict(
                        keepingLocalSession: false
                    )
                }
            }
        }
        switch cookingSessionStore.peerStatus {
        case .compatible:
            EmptyView()
        case .peerRequiresUpdate:
            Text("Update Cookle on iPhone to sync cooking.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .thisDeviceRequiresUpdate:
            Text("Update Cookle on this Watch to sync cooking.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
