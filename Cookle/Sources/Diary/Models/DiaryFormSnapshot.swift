import Foundation

struct DiaryFormSnapshot: Codable, Equatable {
    let date: Date
    let breakfastRecipeIDs: [String]
    let lunchRecipeIDs: [String]
    let dinnerRecipeIDs: [String]
    let note: String

    static func key(
        for diary: Diary?
    ) -> String {
        guard let diary else {
            return "diary.create"
        }

        return "diary.edit.\(String(describing: diary.persistentModelID))"
    }

    func isNearlyEmpty(
        comparedTo referenceDate: Date
    ) -> Bool {
        breakfastRecipeIDs.isEmpty
            && lunchRecipeIDs.isEmpty
            && dinnerRecipeIDs.isEmpty
            && note.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
            && Calendar.current.isDate(
                date,
                inSameDayAs: referenceDate
            )
    }
}
