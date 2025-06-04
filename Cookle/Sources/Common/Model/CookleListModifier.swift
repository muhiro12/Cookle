import SwiftUI

struct CookleListModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func cookleList() -> some View {
        modifier(CookleListModifier())
    }
}
