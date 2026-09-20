import Foundation

enum DiaryDeleteCopy {
    static func title(for diary: Diary) -> String {
        String(localized: "Delete diary for \(formattedDate(for: diary))")
    }

    static func confirmationDialog(for diary: Diary) -> String {
        "\(title(for: diary))? \(message(for: diary))"
    }

    static func message(for diary: Diary) -> String {
        let mealRowCount = (diary.objects ?? []).count
        if mealRowCount == 1 {
            return String(
                localized: "This removes the diary and its one meal row. Recipes stay saved."
            )
        }

        return String(
            localized: "This removes the diary and its \(mealRowCount) meal rows. Recipes stay saved."
        )
    }

    static func successDialog(for diary: Diary) -> String {
        String(localized: "Deleted diary for \(formattedDate(for: diary))")
    }
}

private extension DiaryDeleteCopy {
    static func formattedDate(for diary: Diary) -> String {
        diary.date.formatted(.dateTime.year().month().day())
    }
}
