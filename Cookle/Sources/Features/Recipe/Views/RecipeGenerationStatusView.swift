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
            Creates recipe ideas with Apple's Private Cloud Compute. Requires internet. \
            If PCC is unavailable, your request stays here so you can try again later.
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
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }
}
