import SwiftUI
import TipKit

struct DailySuggestionTip: Tip {
    var title: Text {
        Text("Enable daily suggestions")
    }

    var message: Text? {
        Text("Turn this on to receive one recipe suggestion at your chosen time each day.")
    }

    var image: Image? {
        Image(systemName: "bell.badge")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
