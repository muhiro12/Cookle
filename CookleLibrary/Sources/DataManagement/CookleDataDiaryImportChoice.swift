/// How one conflicting imported diary day is applied.
public enum CookleDataDiaryImportChoice: CaseIterable, Hashable, Sendable {
    /// Keeps the current diary for that day unchanged.
    case keepCurrent
    /// Replaces that day's meals and note with the imported version.
    case useBackup
    /// Keeps both sets of meals and both notes on that day.
    case combine
}
