import SwiftUI

extension View {
    func cookleButtonRowContent(
        alignment: Alignment = .leading
    ) -> some View {
        frame(
            maxWidth: .infinity,
            alignment: alignment
        )
        .contentShape(Rectangle())
    }
}
