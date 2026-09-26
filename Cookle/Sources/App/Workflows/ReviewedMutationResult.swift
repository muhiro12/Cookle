/// Outcome of confirming a reviewed destructive change.
///
/// Only `applied` changes the store. The other cases let the surface report a
/// missing record or show the refreshed review and ask again.
enum ReviewedMutationResult<Review> {
    /// The change matched the review and was saved.
    case applied
    /// The affected records changed; `Review` describes them now.
    case changed(Review)
    /// The reviewed record no longer exists.
    case targetMissing
}
