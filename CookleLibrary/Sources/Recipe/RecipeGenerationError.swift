/// Cloud conditions that stop recipe generation without changing models.
public enum RecipeGenerationError: Error, CaseIterable, Sendable {
    /// The cloud model is not ready or eligible.
    case unavailable
    /// The daily PCC allowance has been exhausted.
    case quotaLimitReached
    /// The request could not reach PCC.
    case networkFailure
    /// The PCC service is temporarily unavailable.
    case serviceUnavailable
}
