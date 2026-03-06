import Foundation
import MHPlatform
import Observation

@MainActor
@Observable
final class MainRouteInbox {
    private let inbox = MHDeepLinkInbox()
    private(set) var pendingURL: URL?

    func store(_ url: URL) async {
        await inbox.ingest(url)
        pendingURL = url
    }

    func consumePendingURL() async -> URL? {
        let pendingURL = await inbox.consumeLatest()
        self.pendingURL = nil
        return pendingURL
    }
}
