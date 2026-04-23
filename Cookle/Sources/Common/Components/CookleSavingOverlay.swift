import SwiftUI

struct CookleSavingOverlay: View {
    private enum Layout {
        static let backdropOpacity = 0.15
        static let cornerRadius: CGFloat = 16
    }

    let title: LocalizedStringKey

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.backdropOpacity)
                .ignoresSafeArea()
            ProgressView(title)
                .padding()
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(
                        cornerRadius: Layout.cornerRadius
                    )
                )
        }
        .accessibilityAddTraits(.isModal)
    }

    init(
        _ title: LocalizedStringKey = "Saving..."
    ) {
        self.title = title
    }
}
