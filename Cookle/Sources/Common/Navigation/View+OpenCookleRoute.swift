import SwiftUI

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
