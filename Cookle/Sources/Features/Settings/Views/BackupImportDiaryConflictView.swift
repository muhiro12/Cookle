import MHUI
import SwiftUI

/// Compares the current and backup diaries of one day and records how the
/// backup day should be imported.
struct BackupImportDiaryConflictView: View {
    let conflict: CookleDataImportReview.DiaryConflict
    let calendar: Calendar

    @Binding var choice: CookleDataDiaryImportChoice?

    var body: some View {
        Form {
            Section {
                ForEach(CookleDataDiaryImportChoice.allCases, id: \.self) { option in
                    BackupImportChoiceRow(
                        title: BackupImportChoiceCopy.title(of: option),
                        isSelected: choice == option
                    ) {
                        choice = option
                    }
                }
            } header: {
                Text("Import Choice")
            } footer: {
                Text(
                    """
                    Replacing changes only this day's meals and note. Combining keeps every current \
                    meal and adds backup meals the day does not already have, keeping repeated meals. \
                    Different notes are both kept, separated by a line.
                    """
                )
            }
            diarySection(
                title: String(localized: "Current Diary"),
                snapshot: conflict.current
            )
            diarySection(
                title: String(localized: "Backup Diary"),
                snapshot: conflict.backup
            )
        }
        .mhFormChrome(.content)
        .navigationTitle(BackupImportChoiceCopy.day(conflict.day, calendar: calendar))
    }
}

private extension BackupImportDiaryConflictView {
    func diarySection(
        title: String,
        snapshot: CookleDataImportReview.DiarySnapshot
    ) -> some View {
        Section {
            if snapshot.meals.isEmpty {
                Text("No meals")
                    .foregroundStyle(.secondary)
            }
            ForEach(Array(snapshot.meals.enumerated()), id: \.offset) { _, meal in
                LabeledContent(mealTitle(meal.type), value: meal.recipeName)
            }
            if snapshot.note.isEmpty == false {
                LabeledContent("Note", value: snapshot.note)
                    .mhKeyValueLayout(.vertical)
            }
        } header: {
            Text(title)
        }
    }

    func mealTitle(_ type: DiaryObjectType) -> String {
        switch type {
        case .breakfast:
            String(localized: "Breakfast")
        case .lunch:
            String(localized: "Lunch")
        case .dinner:
            String(localized: "Dinner")
        }
    }
}
