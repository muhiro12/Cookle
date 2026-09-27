import Foundation

/// Joins diary notes when a backup day is combined with the current day.
enum CookleDataImportNotes {
    private static let separator = "\n\n---\n\n"

    /// Keeps one copy of equal notes, or both differing notes separated clearly.
    static func combined(current: String, backup: String) -> String {
        let trimmedCurrent = current.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBackup = backup.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedBackup.isEmpty || trimmedCurrent == trimmedBackup {
            return current
        }
        if trimmedCurrent.isEmpty {
            return backup
        }
        return current + separator + backup
    }
}
