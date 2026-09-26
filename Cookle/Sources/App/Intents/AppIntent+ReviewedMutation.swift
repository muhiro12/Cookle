import AppIntents

extension AppIntent {
    /// Confirms a destructive change with its reviewed impact and applies it.
    ///
    /// When the affected items change before the change applies, the refreshed
    /// review is confirmed again, up to a few times, instead of applying an
    /// approval that no longer matches the data.
    ///
    /// - Returns: The review that was applied.
    @MainActor
    func confirmReviewedMutation<Review>(
        initialReview: Review,
        dialog: (Review) -> String,
        missingError: any Error,
        apply: (Review) async throws -> ReviewedMutationResult<Review>
    ) async throws -> Review {
        let maximumConfirmationCount = 3
        var review = initialReview
        var isImpactChanged = false

        for _ in 0..<maximumConfirmationCount {
            let prompt = isImpactChanged
                ? ReviewExampleCopy.changedNotice + " " + dialog(review)
                : dialog(review)
            try await requestDeleteConfirmation(
                dialog: .init(
                    stringLiteral: prompt
                )
            )

            switch try await apply(review) {
            case .applied:
                return review
            case .changed(let currentReview):
                review = currentReview
                isImpactChanged = true
            case .targetMissing:
                throw missingError
            }
        }

        throw CookleActionError.reviewedImpactChanged
    }
}
