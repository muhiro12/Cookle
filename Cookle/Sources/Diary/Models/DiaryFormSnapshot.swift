import Foundation
import MHPlatform

nonisolated struct DiaryFormSnapshot: Codable, Equatable, Sendable {
    static let preferenceDescriptor = CodablePreferenceKey.diaryFormSnapshot.preferenceDescriptor(
        Self.self
    )

    let date: Date
    let breakfastRecipeIDs: [String]
    let lunchRecipeIDs: [String]
    let dinnerRecipeIDs: [String]
    let note: String

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

extension FormSnapshotStore where Snapshot == DiaryFormSnapshot {
    init(
        userDefaults: UserDefaults = .standard
    ) {
        self.init(
            descriptor: DiaryFormSnapshot.preferenceDescriptor,
            userDefaults: userDefaults
        )
    }
}
