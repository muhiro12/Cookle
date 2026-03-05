import Foundation

enum MainReviewService {
    private enum Constants {
        static let requestDelaySeconds = Int("2") ?? .zero
        static let lotteryStart = Int("0") ?? .zero
        static let lotteryEnd = Int("10") ?? .zero
    }

    static var requestDelay: Duration {
        .seconds(Constants.requestDelaySeconds)
    }

    static func shouldRequestReview() -> Bool {
        Int.random(in: Constants.lotteryStart..<Constants.lotteryEnd) == .zero
    }
}
