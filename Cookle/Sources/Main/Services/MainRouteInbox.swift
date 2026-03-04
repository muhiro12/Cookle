import Foundation
import Observation

@MainActor
@Observable
final class MainRouteInbox {
    private(set) var pendingURL: URL?

    func store(_ url: URL) {
        pendingURL = url
    }

    func consumePendingURL() -> URL? {
        defer {
            pendingURL = nil
        }
        return pendingURL
    }
}
