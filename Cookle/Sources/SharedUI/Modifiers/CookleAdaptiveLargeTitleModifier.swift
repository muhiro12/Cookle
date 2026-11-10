import SwiftUI

@available(iOS 27.1, *)
struct CookleAdaptiveLargeTitleModifier<Title: View>: ViewModifier {
    @Environment(\.toolbarVerticalEdge)
    private var toolbarVerticalEdge

    let title: Title

    func body(content: Content) -> some View {
        content.toolbar {
            if toolbarVerticalEdge == nil {
                ToolbarItem(placement: .largeTitle) {
                    title
                }
            }
        }
    }
}
