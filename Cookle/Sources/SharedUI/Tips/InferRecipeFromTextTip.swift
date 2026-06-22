import SwiftUI
import TipKit

struct InferRecipeFromTextTip: Tip {
    var title: Text {
        Text("Paste recipe text")
    }

    var message: Text? {
        Text("Extract a draft from copied ingredients and steps.")
    }

    var image: Image? {
        Image(systemName: "text.quote")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
