import CookleLibrary
import SwiftUI

struct RecipeGenerationProgressView: View {
    private enum Layout {
        static let overlayOpacity = 0.2
        static let spacing = 12.0
        static let cornerRadius = 16.0
    }

    let status: RecipeGenerationStatus?

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.overlayOpacity).ignoresSafeArea()
            if let status {
                VStack(spacing: Layout.spacing) {
                    ProgressView()
                    RecipeGenerationStatusView(status: status)
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: Layout.cornerRadius))
                .padding()
            } else {
                ProgressView()
            }
        }
    }
}
