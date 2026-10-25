import SwiftUI

struct DiaryAdditionLabel: View {
    let title: LocalizedStringKey

    var body: some View {
        Label(title, systemImage: systemImageName)
    }

    private var systemImageName: String {
        if #available(iOS 26.0, *) {
            return "book.badge.plus"
        } else {
            return "book"
        }
    }
}
