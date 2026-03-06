import MHPlatform

typealias CookleReviewRequester = @MainActor @Sendable () async -> MHReviewRequestOutcome
