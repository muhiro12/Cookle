import Foundation

/// Editable persisted content for a diary aggregate.
public struct DiaryContent {
    /// Calendar date represented by the diary entry.
    public var date: Date
    /// Meal objects attached to the diary entry.
    public var objects: [DiaryObject]
    /// Freeform diary note.
    public var note: String

    /// Creates editable persisted diary content.
    public init(
        date: Date,
        objects: [DiaryObject],
        note: String
    ) {
        self.date = date
        self.objects = objects
        self.note = note
    }
}
