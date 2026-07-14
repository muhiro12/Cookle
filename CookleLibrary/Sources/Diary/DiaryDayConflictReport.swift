/// Summary of legacy diary rows that share a calendar day.
public struct DiaryDayConflictReport: Equatable, Sendable {
    /// Number of calendar days represented by more than one diary.
    public let conflictingDayCount: Int
    /// Number of diaries beyond the one canonical diary retained for each day.
    public let excessDiaryCount: Int

    /// Whether the store contains any calendar-day conflict.
    public var hasConflicts: Bool {
        conflictingDayCount > .zero
    }
}
