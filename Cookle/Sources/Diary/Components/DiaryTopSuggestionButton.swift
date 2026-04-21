import SwiftUI

struct DiaryTopSuggestionButton: View {
    let suggestion: DiaryTopSuggestion
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Label {
                VStack(alignment: .leading) {
                    suggestion.actionTitle
                    suggestion.detailText
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            } icon: {
                Image(systemName: "sparkles")
                    .accessibilityHidden(true)
            }
            .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        List {
            Section {
                DiaryTopSuggestionButton(
                    suggestion: .init(
                        date: .now,
                        recipeName: "Spaghetti Carbonara",
                        recipeStableIdentifier: "preview-recipe",
                        mealType: .dinner
                    )
                ) {
                    // Preview only.
                }
            }
        }
        .navigationTitle("Diaries")
    }
}
