import Foundation

enum MainReviewService {
    static var requestDelay: Duration {
        .seconds(2)
    }

    static func shouldRequestReview() -> Bool {
        Int.random(in: 0..<10) == .zero
    }
}
