import CookleLibrary
import SwiftUI

@available(iOS 26.0, *)
struct RecipeGenerationControlsView: View {
    @Binding var onDeviceOnly: Bool
    let status: RecipeGenerationStatus?
    let isLoading: Bool

    private var currentStatus: RecipeGenerationStatus {
        status ?? RecipeModelGenerationOperations.plannedStatus(onDeviceOnly: onDeviceOnly)
    }

    var body: some View {
        if RecipeModelGenerationOperations.supportsCloudSelection {
            Picker("Processing Method", selection: $onDeviceOnly) {
                Text("PCC Preferred").tag(false)
                Text("On-Device Only").tag(true)
            }
            .pickerStyle(.menu)
            .disabled(isLoading)
        }
        RecipeGenerationStatusView(status: currentStatus)
        if currentStatus == .privateCloudCompute,
           RecipeModelGenerationOperations.isApproachingCloudLimit {
            Text("Private Cloud Compute is nearing its daily usage limit.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        if !RecipeModelGenerationOperations.canGenerate(onDeviceOnly: onDeviceOnly) {
            Text("The selected model is unavailable. Change the processing method or try again later.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
