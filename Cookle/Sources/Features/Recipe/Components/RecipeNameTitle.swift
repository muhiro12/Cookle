import MHUI
import SwiftUI

struct RecipeNameTitle: View {
    private enum Layout {
        static let lineLimit = 2
        static let minimumScaleFactor = 0.8
    }

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    private let name: String

    var body: some View {
        Text(name)
            .mhTextStyle(.screenTitle)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : Layout.lineLimit)
            .minimumScaleFactor(
                dynamicTypeSize.isAccessibilitySize ? 1 : Layout.minimumScaleFactor
            )
            .allowsTightening(dynamicTypeSize.isAccessibilitySize == false)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }

    init(_ name: String) {
        self.name = name
    }
}

#Preview("Long recipe name") {
    RecipeNameTitle("Spaghetti Carbonara with Seasonal Vegetables")
        .padding()
}

#Preview("Long recipe name, accessibility text") {
    RecipeNameTitle("Spaghetti Carbonara with Seasonal Vegetables")
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
}
