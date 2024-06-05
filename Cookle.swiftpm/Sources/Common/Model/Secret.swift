import SwiftUI

@Observable
final class Secret {
    let groupID: String
    let productID: String

    init(_ value: [String: String]) {
        groupID = value["groupID"]!
        productID = value["productID"]!
    }
}

public extension View {
    func secret(_ value: [String: String]) -> some View {
        environment(Secret(value))
    }
}
