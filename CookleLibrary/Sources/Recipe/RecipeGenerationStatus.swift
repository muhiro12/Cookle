/// Transient processing information for an unsaved AI recipe draft.
public enum RecipeGenerationStatus: Equatable, Sendable {
    /// The request uses Apple's Private Cloud Compute model.
    case privateCloudCompute
    /// The request uses the on-device model, optionally after cloud fallback.
    case onDevice(fallbackReason: FallbackReason? = nil)

    /// Recoverable cloud conditions that permit one on-device attempt.
    public enum FallbackReason: Error, CaseIterable, Sendable {
        /// The cloud model is not ready or eligible.
        case unavailable
        /// The daily PCC allowance has been exhausted.
        case quotaLimitReached
        /// The request could not reach PCC.
        case networkFailure
        /// The PCC service is temporarily unavailable.
        case serviceUnavailable
    }
}
