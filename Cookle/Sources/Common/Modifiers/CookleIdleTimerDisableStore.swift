import UIKit

@MainActor
enum CookleIdleTimerDisableStore {
    private static let minimumRequestCount = 0
    private static let requestStep = 1

    private static var requestCount = minimumRequestCount

    static func acquire() {
        requestCount += requestStep
        applyCurrentState()
    }

    static func release() {
        requestCount = max(
            requestCount - requestStep,
            minimumRequestCount
        )
        applyCurrentState()
    }

    private static func applyCurrentState() {
        UIApplication.shared.isIdleTimerDisabled = requestCount > minimumRequestCount
    }
}
