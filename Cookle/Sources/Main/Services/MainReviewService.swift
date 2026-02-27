import Foundation

enum MainReviewService {
    static func shouldRequestReview() -> Bool {
        Int.random(in: 0..<10) == .zero
    }

    static var requestDelay: Duration {
        .seconds(2)
    }
}
