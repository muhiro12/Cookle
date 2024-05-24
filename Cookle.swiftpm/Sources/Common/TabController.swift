import SwiftUI

@Observable
final class TabController {
    @ObservationIgnored
    @Published
    private(set) var state: (oldValue: Tab, newValue: Tab)
    
    init(initialTab: Tab) {
        state = (initialTab, initialTab)
    }
    
    var selection: Binding<Tab> {
        .init(
            get: {
                self.state.newValue
            },
            set: {
                self.state = (self.state.newValue, $0)
            }
        )
    }
}
