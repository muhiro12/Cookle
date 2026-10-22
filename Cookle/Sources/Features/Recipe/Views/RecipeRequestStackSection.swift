import SwiftUI

@available(iOS 26.0, *)
struct RecipeRequestStackSection: View {
    @Binding var text: String
    let isLoading: Bool
    let editRequest: () -> Void

    private var preferences: [String] {
        text.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }

    var body: some View {
        Section {
            if preferences.isEmpty {
                Text("Add ingredients or preferences below, then create a draft.")
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(preferences.enumerated()), id: \.offset) { _, preference in
                Text(verbatim: preference)
                    .textSelection(.enabled)
            }
            .onDelete { offsets in
                text = preferences.enumerated()
                    .filter { !offsets.contains($0.offset) }
                    .map(\.element)
                    .joined(separator: "\n")
            }
            .deleteDisabled(isLoading)
            if !preferences.isEmpty {
                Button("Edit Request", systemImage: "pencil", action: editRequest)
                    .disabled(isLoading)
            }
        } header: {
            Text("Recipe Request")
        } footer: {
            Text("Adding a preference does not run AI. Create Draft uses the preferences listed here.")
        }
    }
}
