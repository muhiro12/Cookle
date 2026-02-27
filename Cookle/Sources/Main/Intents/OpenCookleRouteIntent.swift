import AppIntents
import Foundation

struct OpenCookleRouteIntent: AppIntent {
    static let title: LocalizedStringResource = .init("Open Cookle Route")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @Parameter(title: "URL")
    private var url: URL

    init() {}

    init(url: URL) {
        self.url = url
    }

    @MainActor
    func perform() -> some IntentResult {
        CookleIntentRouteStore.store(url)
        return .result()
    }
}
