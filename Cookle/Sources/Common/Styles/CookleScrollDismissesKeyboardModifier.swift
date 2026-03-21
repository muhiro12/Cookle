import SwiftUI

private struct CookleScrollDismissesKeyboardModifier: ViewModifier {
    let keyboardDismissMode: ScrollDismissesKeyboardMode?

    func body(content: Content) -> some View {
        if let keyboardDismissMode {
            content.scrollDismissesKeyboard(keyboardDismissMode)
        } else {
            content
        }
    }
}
