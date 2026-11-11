import SwiftUI

@MainActor
@Observable
final class CookleActiveEditors {
    struct DeferralModifier: ViewModifier {
        @Environment(CookleActiveEditors.self)
        private var activeEditors: CookleActiveEditors?

        @State private var editorID = UUID()

        let isEditing: Bool

        func body(content: Content) -> some View {
            content
                .onAppear(perform: updateRegistration)
                .onChange(of: isEditing, updateRegistration)
                .onDisappear {
                    activeEditors?.editorIDs.remove(editorID)
                }
        }

        private func updateRegistration() {
            if isEditing {
                activeEditors?.editorIDs.insert(editorID)
            } else {
                activeEditors?.editorIDs.remove(editorID)
            }
        }
    }

    private var editorIDs: Set<UUID> = []

    var isEditing: Bool {
        !editorIDs.isEmpty
    }
}

extension View {
    func deferICloudSyncWhileEditing(_ isEditing: Bool = true) -> some View {
        modifier(CookleActiveEditors.DeferralModifier(isEditing: isEditing))
    }
}
