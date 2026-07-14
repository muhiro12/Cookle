import Foundation
import SwiftUI

extension View {
    func cookleTopLevelNavigationChrome(
        _ title: LocalizedStringResource,
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
