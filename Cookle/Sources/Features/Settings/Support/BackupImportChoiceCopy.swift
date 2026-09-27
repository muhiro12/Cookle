import CookleLibrary
import Foundation
import SwiftData

/// Words for import conflict choices, shared by the review list and detail screens.
enum BackupImportChoiceCopy {
    static func status(
        of choice: CookleDataRecipeImportChoice?,
        in conflict: CookleDataImportReview.RecipeConflict
    ) -> String? {
        switch choice {
        case .keepCurrent(let target):
            keepCurrentTitle(for: target, in: conflict)
        case .useBackup(let target):
            useBackupTitle(for: target, in: conflict)
        case .keepBoth:
            String(localized: "Keep Both")
        case nil:
            nil
        }
    }

    static func status(of choice: CookleDataDiaryImportChoice?) -> String? {
        choice.map(title)
    }

    static func keepCurrentTitle(
        for target: PersistentIdentifier,
        in conflict: CookleDataImportReview.RecipeConflict
    ) -> String {
        guard conflict.candidates.count > 1,
              let number = candidateNumber(of: target, in: conflict) else {
            return String(localized: "Keep Current Recipe")
        }

        return String(localized: "Keep Current Recipe \(number)")
    }

    static func useBackupTitle(
        for target: PersistentIdentifier,
        in conflict: CookleDataImportReview.RecipeConflict
    ) -> String {
        guard conflict.candidates.count > 1,
              let number = candidateNumber(of: target, in: conflict) else {
            return String(localized: "Replace Current Recipe with Backup")
        }

        return String(localized: "Replace Current Recipe \(number) with Backup")
    }

    static func title(of choice: CookleDataDiaryImportChoice) -> String {
        switch choice {
        case .keepCurrent:
            String(localized: "Keep Current Diary")
        case .useBackup:
            String(localized: "Replace with Backup Diary")
        case .combine:
            String(localized: "Combine Both")
        }
    }

    static func day(_ day: Date, calendar: Calendar) -> String {
        day.formatted(
            Date.FormatStyle(
                date: .long,
                time: .omitted,
                calendar: calendar,
                timeZone: calendar.timeZone
            )
        )
    }
}

private extension BackupImportChoiceCopy {
    static func candidateNumber(
        of target: PersistentIdentifier,
        in conflict: CookleDataImportReview.RecipeConflict
    ) -> Int? {
        conflict.candidates.firstIndex { candidate in
            candidate.id == target
        }
        .map { index in
            index + 1
        }
    }
}
