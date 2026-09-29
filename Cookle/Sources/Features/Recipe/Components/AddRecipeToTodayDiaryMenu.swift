import SwiftData
import SwiftUI

/// Adds the recipe to one of today's meals from a submenu.
///
/// Use this inside a context menu, where `AddRecipeToTodayDiaryButton`'s meal
/// dialog would close together with the menu. The meal list takes the place of
/// that dialog, and the same `DiaryActionService` mutation performs the add.
struct AddRecipeToTodayDiaryMenu: View {
    @Environment(Recipe.self)
    private var recipe
    @Environment(\.modelContext)
    private var context
    @Environment(DiaryActionService.self)
    private var diaryActionService

    private let reportFailure: (String) -> Void

    var body: some View {
        Menu {
            ForEach(DiaryObjectType.allCases) { type in
                Button(type.mealTitle) {
                    add(to: type)
                }
            }
        } label: {
            Label {
                Text("Add to Today's Diary")
            } icon: {
                Image(systemName: "book.badge.plus")
                    .accessibilityHidden(true)
            }
        }
    }

    /// Creates the submenu.
    ///
    /// - Parameter reportFailure: Receives the error message so an ancestor
    ///   that outlives the menu can present it.
    init(
        reportFailure: @escaping (String) -> Void
    ) {
        self.reportFailure = reportFailure
    }
}

private extension AddRecipeToTodayDiaryMenu {
    func add(
        to type: DiaryObjectType
    ) {
        // Resolve the environment while the menu is still installed; the task
        // finishes after the menu has closed.
        let recipe = recipe
        let context = context
        let diaryActionService = diaryActionService
        let reportFailure = reportFailure
        Task {
            do {
                try await diaryActionService.add(
                    context: context,
                    date: .now,
                    recipe: recipe,
                    type: type
                )
            } catch {
                reportFailure(error.localizedDescription)
            }
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    AddRecipeToTodayDiaryMenu { _ in
        // Preview failures are not presented.
    }
    .environment(recipes[0])
}
