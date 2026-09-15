import SwiftData
import SwiftUI

struct RecipeDiaryHistoryView: View {
    @Environment(Recipe.self)
    private var recipe

    var body: some View {
        let diaries = Set(recipe.diaries ?? []).sorted { lhs, rhs in
            lhs.date > rhs.date
        }
        List {
            Section {
                ForEach(diaries) { diary in
                    RecipeDiaryRow(diary: diary)
                }
            } header: {
                Text("Diaries (\(diaries.count))")
            }
        }
        .navigationTitle("Diaries")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    NavigationStack {
        RecipeDiaryHistoryView()
            .environment(recipes[0])
    }
}
