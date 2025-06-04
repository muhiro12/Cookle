import SwiftUI

struct CookleListModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .listRowSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
    }
}

extension View {
    func cookleList() -> some View {
        modifier(CookleListModifier())
    }
}
