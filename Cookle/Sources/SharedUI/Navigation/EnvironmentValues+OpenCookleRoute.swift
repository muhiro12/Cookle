import SwiftUI

extension EnvironmentValues {
    var openCookleRoute: OpenCookleRouteAction {
        get {
            self[OpenCookleRouteAction.Key.self]
        }
        set {
            self[OpenCookleRouteAction.Key.self] = newValue
        }
    }
}
