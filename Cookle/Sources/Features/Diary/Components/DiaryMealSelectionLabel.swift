import MHUI
import SwiftUI

struct DiaryMealSelectionLabel: View {
    @Environment(\.mhTheme)
    private var theme

    let type: DiaryObjectType
    let recipeNames: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.inline) {
            LabeledContent {
                Text("Recipes: \(recipeNames.count)")
            } label: {
                Text(type.title)
            }
            ForEach(recipeNames.indices, id: \.self) { index in
                Text(verbatim: recipeNames[index])
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Meal selections") {
    NavigationStack {
        Form {
            Section {
                NavigationLink(value: DiaryObjectType.breakfast) {
                    DiaryMealSelectionLabel(type: .breakfast, recipeNames: [])
                }
            }
            Section {
                NavigationLink(value: DiaryObjectType.lunch) {
                    DiaryMealSelectionLabel(type: .lunch, recipeNames: ["野菜スープ"])
                }
            }
            Section {
                NavigationLink(value: DiaryObjectType.dinner) {
                    DiaryMealSelectionLabel(
                        type: .dinner,
                        recipeNames: ["スパゲッティ・カルボナーラ", "野菜スープ"]
                    )
                }
            }
        }
        .mhFormChrome()
        .navigationTitle("Diary")
    }
}
