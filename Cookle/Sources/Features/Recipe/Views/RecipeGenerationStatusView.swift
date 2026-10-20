import CookleLibrary
import SwiftUI

struct RecipeGenerationStatusView: View {
    private enum Layout {
        static let spacing = 4.0
    }

    let status: RecipeGenerationStatus
    var isCompleted = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            switch status {
            case .privateCloudCompute:
                Label {
                    if isCompleted {
                        Text("Created with Private Cloud Compute")
                    } else {
                        Text("Private Cloud Compute")
                    }
                } icon: {
                    Image(systemName: "cloud")
                }
                if !isCompleted {
                    Text("Prefers Apple's Private Cloud Compute, with on-device fallback when unavailable.")
                }
            case .onDevice(let reason):
                Label {
                    if isCompleted {
                        Text("Created on device")
                    } else {
                        Text("On-Device Model")
                    }
                } icon: {
                    Image(systemName: "iphone")
                }
                if let reason {
                    reasonText(reason)
                } else if !isCompleted {
                    Text("Your recipe request is processed on this device.")
                }
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func reasonText(_ reason: RecipeGenerationStatus.FallbackReason) -> some View {
        switch reason {
        case .unavailable:
            Text("Private Cloud Compute is not ready on this device.")
        case .quotaLimitReached:
            Text("Private Cloud Compute's daily usage limit has been reached.")
        case .networkFailure:
            Text("Private Cloud Compute could not be reached.")
        case .serviceUnavailable:
            Text("Private Cloud Compute is temporarily unavailable.")
        }
    }
}
