import SwiftUI

struct CookleTopLevelNavigationChromeModifier: ViewModifier {
    let title: LocalizedStringKey
    let keyboardDismissMode: ScrollDismissesKeyboardMode?

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbarRole(.editor)
            .modifier(
                CookleScrollDismissesKeyboardModifier(
                    keyboardDismissMode: keyboardDismissMode
                )
            )
    }
}
