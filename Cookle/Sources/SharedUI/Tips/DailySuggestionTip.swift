import SwiftUI
import TipKit

struct DailySuggestionTip: Tip {
    var title: Text {
        Text("Turn on daily suggestions")
    }

    var message: Text? {
        Text("Get one recipe suggestion at your chosen time.")
    }

    var image: Image? {
        Image(systemName: "bell.badge")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
