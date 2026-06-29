import MHUI
import SwiftUI

struct CookleTopLevelNavigationChromeModifier: ViewModifier {
    let title: LocalizedStringKey
    let keyboardDismissMode: ScrollDismissesKeyboardMode?

    func body(content: Content) -> some View {
        content
            .cookleListChrome()
            .navigationTitle(title)
            .toolbarRole(.editor)
            .modifier(
                CookleScrollDismissesKeyboardModifier(
                    keyboardDismissMode: keyboardDismissMode
                )
            )
    }
}
