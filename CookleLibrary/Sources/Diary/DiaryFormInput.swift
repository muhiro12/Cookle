import Foundation

/// Unpersisted diary form input grouped by meal type.
public struct DiaryFormInput {
    /// Calendar date represented by the diary entry.
    public var date: Date
    /// Recipes selected for breakfast.
    public var breakfasts: [Recipe]
    /// Recipes selected for lunch.
    public var lunches: [Recipe]
    /// Recipes selected for dinner.
    public var dinners: [Recipe]
    /// Freeform diary note.
    public var note: String

    /// Creates diary form input.
    public init(
        date: Date,
        breakfasts: [Recipe] = [],
        lunches: [Recipe] = [],
        dinners: [Recipe] = [],
        note: String = ""
    ) {
        self.date = date
        self.breakfasts = breakfasts
        self.lunches = lunches
        self.dinners = dinners
        self.note = note
    }
}
