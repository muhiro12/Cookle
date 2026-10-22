import SwiftUI

/// Shared entry for the system tab accessory and its fixed-position fallback.
@available(iOS 26.0, *)
struct RecipeRequestAccessoryView: View {
    private enum Layout {
        static let minimumButtonHeight = 44.0
    }

    static let transitionID = "recipePreference"

    let isLoading: Bool
    let transition: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Add Preference", systemImage: "plus.circle.fill")
                .frame(maxWidth: .infinity, minHeight: Layout.minimumButtonHeight, alignment: .leading)
                .contentShape(.rect)
        }
        .padding(.horizontal)
        .accessibilityIdentifier("recipePreferenceEntry")
        .matchedTransitionSource(id: Self.transitionID, in: transition)
        .disabled(isLoading)
    }
}
