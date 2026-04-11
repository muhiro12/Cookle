import SwiftData
import SwiftUI

struct AddRecipeToTodayDiaryButton: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.modelContext)
    private var context
    @Environment(DiaryActionService.self)
    private var diaryActionService

    @State private var isPresented = false
    @State private var isErrorPresented = false
    @State private var errorMessage = ""

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label {
                Text("Add to Today's Diary")
            } icon: {
                Image(systemName: "book.badge.plus")
                    .accessibilityHidden(true)
            }
        }
        .confirmationDialog(
            Text("Add to Today's Diary"),
            isPresented: $isPresented
        ) {
            ForEach(DiaryObjectType.allCases) { type in
                Button(type.mealTitle) {
                    Task {
                        await add(
                            to: type
                        )
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text("Choose a meal for \(recipe.name).")
        }
        .alert(
            Text("Cannot Add to Diary"),
            isPresented: $isErrorPresented
        ) {
            Button("OK", role: .cancel) {
                // Dismisses the alert.
            }
        } message: {
            Text(errorMessage)
        }
    }
}

private extension AddRecipeToTodayDiaryButton {
    @MainActor
    func add(
        to type: DiaryObjectType
    ) async {
        do {
            errorMessage = ""
            _ = try await diaryActionService.add(
                context: context,
                date: .now,
                recipe: recipe,
                type: type
            )
        } catch {
            errorMessage = error.localizedDescription
            isErrorPresented = true
        }
    }
}

private extension DiaryObjectType {
    var mealTitle: LocalizedStringKey {
        switch self {
        case .breakfast:
            "Breakfast"
        case .lunch:
            "Lunch"
        case .dinner:
            "Dinner"
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    AddRecipeToTodayDiaryButton()
        .environment(recipes[0])
}
