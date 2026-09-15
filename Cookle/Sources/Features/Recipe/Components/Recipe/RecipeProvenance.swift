import Foundation
import MHUI
import SwiftUI

struct RecipeProvenance: View {
    @Environment(\.mhTheme)
    private var theme

    let createdAt: Date
    let updatedAt: Date

    var body: some View {
        VStack(spacing: theme.spacing.inline) {
            LabeledContent("Created At") {
                Text(createdAt, format: .dateTime.year().month().day())
            }
            LabeledContent("Updated At") {
                Text(updatedAt, format: .dateTime.year().month().day())
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
