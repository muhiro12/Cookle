import Foundation
import SwiftUI

struct CookleTopLevelNavigationChromeModifier: ViewModifier {
    let title: LocalizedStringResource
    let keyboardDismissMode: ScrollDismissesKeyboardMode?

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbarRole(.editor)
            .modifier(
                CookleScrollDismissesKeyboardModifier(
                    keyboardDismissMode: keyboardDismissMode
                )
            )
    }
}
