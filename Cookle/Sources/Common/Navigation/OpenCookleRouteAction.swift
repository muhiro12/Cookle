import SwiftUI

struct OpenCookleRouteAction {
    private let action: @MainActor (CookleRoute) -> Void

    init(
        action: @escaping @MainActor (CookleRoute) -> Void = { _ in }
    ) {
        self.action = action
    }

    @MainActor
    func callAsFunction(_ route: CookleRoute) {
        action(route)
    }
}

private struct OpenCookleRouteActionKey: EnvironmentKey {
    static let defaultValue = OpenCookleRouteAction()
}

extension EnvironmentValues {
    var openCookleRoute: OpenCookleRouteAction {
        get {
            self[OpenCookleRouteActionKey.self]
        }
        set {
            self[OpenCookleRouteActionKey.self] = newValue
        }
    }
}

extension View {
    func openCookleRoute(
        _ action: @escaping @MainActor (CookleRoute) -> Void
    ) -> some View {
        environment(
            \.openCookleRoute,
            OpenCookleRouteAction(action: action)
        )
    }
}
