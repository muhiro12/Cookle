import StoreKit
import UIKit

@MainActor
final class CookleReviewRequester {
    func requestIfNeeded() async {
        guard MainReviewService.shouldRequestReview() else {
            return
        }

        try? await Task.sleep(for: MainReviewService.requestDelay)

        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ scene in
                    scene as? UIWindowScene
                })
                .first(where: { windowScene in
                    windowScene.activationState == .foregroundActive
                }) else {
            return
        }

        SKStoreReviewController.requestReview(in: windowScene)
    }
}
