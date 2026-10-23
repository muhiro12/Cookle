import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct RecipeGenerationControlsView: View {
    let isLoading: Bool

    var body: some View {
        RecipeGenerationStatusView(status: .privateCloudCompute)
        if !isLoading, let reason = RecipeModelGenerationOperations.unavailableReason {
            Text(RecipeModelInferenceError(error: reason).localizedDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else if RecipeModelGenerationOperations.isApproachingCloudLimit {
            Text("Private Cloud Compute is nearing its daily usage limit.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
