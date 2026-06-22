import SwiftUI

struct DiaryTopSuggestionButton: View {
    private enum Constants {
        static let detailLineLimit = 2
    }

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
                        .lineLimit(Constants.detailLineLimit)
                }
            } icon: {
                Image(systemName: "sparkles")
                    .accessibilityHidden(true)
            }
            .cookleButtonRowContent()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(suggestion.accessibilityLabel))
        .accessibilityHint(Text("Opens an editable diary draft."))
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

private extension DiaryTopSuggestion {
    var accessibilityLabel: String {
        "Add \(recipeName) to today's \(mealAccessibilityName)"
    }

    var mealAccessibilityName: String {
        switch mealType {
        case .breakfast:
            return "breakfast"
        case .lunch:
            return "lunch"
        case .dinner:
            return "dinner"
        }
    }
}
