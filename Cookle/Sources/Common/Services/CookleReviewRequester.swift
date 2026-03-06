import MHPlatform

@MainActor
final class CookleReviewRequester {
    func requestIfNeeded() async {
        _ = await MainReviewService.requestIfNeeded()
    }
}
