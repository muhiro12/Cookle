import SwiftUI
import TipKit

struct DailySuggestionTip: Tip {
    var title: Text {
        Text("Turn on daily suggestions")
    }

    var message: Text? {
        Text("Get recipe suggestions around the meal times you use Cookle.")
    }

    var image: Image? {
        Image(systemName: "bell.badge")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
