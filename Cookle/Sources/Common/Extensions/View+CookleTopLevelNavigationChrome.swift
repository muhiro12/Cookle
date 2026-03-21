import SwiftUI

extension View {
    func cookleTopLevelNavigationChrome(
        _ title: LocalizedStringKey,
        keyboardDismissMode: ScrollDismissesKeyboardMode? = nil
    ) -> some View {
        modifier(
            CookleTopLevelNavigationChromeModifier(
                title: title,
                keyboardDismissMode: keyboardDismissMode
            )
        )
    }
}
