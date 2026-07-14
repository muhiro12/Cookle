/// Summary of a completed duplicate-day repair.
public struct DiaryDayRepairSummary: Equatable, Sendable {
    /// Number of calendar days whose diaries were merged.
    public let mergedDayCount: Int
    /// Number of redundant diary roots removed after their content was merged.
    public let removedDiaryCount: Int
}
