import MHPlatform

enum CookleReviewPolicy {
    private enum Constants {
        static let lotteryMaxExclusive = 10
        static let requestDelaySeconds = 2
    }

    static var request: MHReviewPolicy {
        .init(
            lotteryMaxExclusive: Constants.lotteryMaxExclusive,
            requestDelay: .seconds(Constants.requestDelaySeconds)
        )
    }
}
