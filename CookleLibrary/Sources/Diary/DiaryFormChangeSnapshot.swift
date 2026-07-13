import Foundation

/// Semantic diary form state used to detect unsaved changes.
public struct DiaryFormChangeSnapshot: Equatable, Sendable {
    private let date: Date
    private let breakfastRecipeIDs: [String]
    private let lunchRecipeIDs: [String]
    private let dinnerRecipeIDs: [String]
    private let note: String

    /// Creates a snapshot normalized to a calendar day and set-like meal selections.
    public init(
        date: Date,
        breakfastRecipeIDs: [String],
        lunchRecipeIDs: [String],
        dinnerRecipeIDs: [String],
        note: String,
        calendar: Calendar = .current
    ) {
        self.date = calendar.startOfDay(for: date)
        self.breakfastRecipeIDs = breakfastRecipeIDs.sorted()
        self.lunchRecipeIDs = lunchRecipeIDs.sorted()
        self.dinnerRecipeIDs = dinnerRecipeIDs.sorted()
        self.note = note
    }
}
