import SwiftUI

struct RecipeTitleBadge: View {
    private enum Layout {
        static let minimumScaleFactor: CGFloat = 0.85
        static let innerPadding: CGFloat = 10
        static let cornerRadius: CGFloat = 10
        static let outerPadding: CGFloat = 8
        static let bottomPadding: CGFloat = 4
    }

    let text: String
    let lineLimit: Int

    var body: some View {
        Text(text)
            .privacySensitive()
            .font(.headline)
            .foregroundStyle(.primary)
            .lineLimit(lineLimit)
            .minimumScaleFactor(Layout.minimumScaleFactor)
            .padding(Layout.innerPadding)
            .background(.thinMaterial, in: .rect(cornerRadius: Layout.cornerRadius))
            .padding(Layout.outerPadding)
            .padding(.bottom, Layout.bottomPadding)
    }
}
