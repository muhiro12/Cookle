import Foundation
import MHPlatform

enum MainReviewService {
    private enum Constants {
        static let lotteryMaxExclusive = 10
        static let requestDelaySeconds = 2
    }

    static var reviewPolicy: MHReviewPolicy {
        .init(
            lotteryMaxExclusive: Constants.lotteryMaxExclusive,
            requestDelay: .seconds(Constants.requestDelaySeconds)
        )
    }

    @MainActor
    static func requestIfNeeded() async -> MHReviewRequestOutcome {
        await CookleApp.requestReviewIfNeeded(
            policy: reviewPolicy,
            source: #fileID
        )
    }
}
