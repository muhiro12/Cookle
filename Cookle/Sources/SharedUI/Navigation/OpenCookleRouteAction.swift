import SwiftUI

struct OpenCookleRouteAction {
    enum Key: EnvironmentKey {
        static let defaultValue = OpenCookleRouteAction()
    }

    private static let defaultAction: @MainActor (CookleRoute) -> Void = { route in
        _ = route
    }

    private let action: @MainActor (CookleRoute) -> Void

    init(
        action: @escaping @MainActor (CookleRoute) -> Void = Self.defaultAction
    ) {
        self.action = action
    }

    @MainActor
    func callAsFunction(_ route: CookleRoute) {
        action(route)
    }
}
