import SwiftUI

struct CookleSavingOverlay: View {
    let title: LocalizedStringKey

    init(
        _ title: LocalizedStringKey = "Saving..."
    ) {
        self.title = title
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            ProgressView(title)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .accessibilityAddTraits(.isModal)
    }
}
