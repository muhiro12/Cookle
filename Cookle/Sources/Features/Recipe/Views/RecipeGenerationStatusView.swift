import CookleLibrary
import SwiftUI

struct RecipeGenerationStatusView: View {
    private enum Layout {
        static let spacing = 4.0
    }

    let status: RecipeGenerationStatus
    var isCompleted = false

    private var cloudDescription: Text {
        Text(
            """
            Prefers Apple's Private Cloud Compute for more detailed recipe ideas. \
            Requires internet; uses the on-device model when unavailable.
            """
        )
    }

    private var onDeviceDescription: Text {
        Text(
            """
            Creates recipe ideas on this device without internet. \
            Steps and explanations may be brief.
            """
        )
    }

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
                    cloudDescription
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
                    onDeviceDescription
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
