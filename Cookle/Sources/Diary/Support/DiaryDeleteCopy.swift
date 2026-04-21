import Foundation

enum DiaryDeleteCopy {
    static func title(for diary: Diary) -> String {
        "Delete diary for \(formattedDate(for: diary))"
    }

    static func confirmationDialog(for diary: Diary) -> String {
        "\(title(for: diary))? \(message(for: diary))"
    }

    static func message(for diary: Diary) -> String {
        let mealRowCount = diary.objects.orEmpty.count
        let mealRowLabel = mealRowCount == 1 ? "meal row" : "meal rows"

        return "This removes the diary and its \(mealRowCount) \(mealRowLabel). Recipes stay saved."
    }

    static func successDialog(for diary: Diary) -> String {
        "Deleted diary for \(formattedDate(for: diary))"
    }
}

private extension DiaryDeleteCopy {
    static func formattedDate(for diary: Diary) -> String {
        diary.date.formatted(.dateTime.year().month().day())
    }
}
