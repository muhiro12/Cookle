import SwiftUI

struct OnTabSelectedModifier: ViewModifier {
    @Environment(TabController.self) private var tabController

    private let onSelected: (Tab, Tab) -> Void

    init(onSelected: @escaping (Tab, Tab) -> Void) {
        self.onSelected = onSelected
    }

    func body(content: Content) -> some View {
        content
            .onReceive(tabController.$state) {
                onSelected($0.oldValue, $0.newValue)
            }
    }
}

extension View {
    func onTabSelected(_ onSelected: @escaping (Tab, Tab) -> Void) -> some View {
        modifier(
            OnTabSelectedModifier(onSelected: onSelected)
        )
    }
}
