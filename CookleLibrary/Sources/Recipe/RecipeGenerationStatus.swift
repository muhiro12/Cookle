/// Transient processing information for an unsaved AI recipe draft.
public enum RecipeGenerationStatus: Equatable, Sendable {
    /// The request uses Apple's Private Cloud Compute model.
    case privateCloudCompute
}
