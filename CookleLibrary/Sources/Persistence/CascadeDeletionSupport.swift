/// Prepares cascade-owned rows so a later rollback can undo their deletion.
///
/// Deleting a parent whose cascade-owned rows are still faults makes SwiftData
/// trap inside `ModelContext.rollback()`:
///
/// ```text
/// Unexpected backing data for snapshot creation:
/// SwiftData._FullFutureBackingData<…>
/// ```
///
/// That is a `fatalError`, so a failed save takes the process down instead of
/// recovering. It reproduces only when a row is owned by two cascade
/// relationships — as `DiaryObject`, `IngredientObject`, and `PhotoObject` all
/// are — which is why deleting the child rows before the parent, the ordering
/// `DataResetService` uses, does not prevent it on these paths.
///
/// Reading a **stored** property first gives each row real backing data.
/// `persistentModelID`, `isDeleted`, and the description are not enough.
enum CascadeDeletionSupport {
    /// Materializes cascade-owned rows before their parent is deleted.
    static func materialize(_ rows: [some SubObject]) {
        for row in rows {
            _ = row.order
        }
    }
}
