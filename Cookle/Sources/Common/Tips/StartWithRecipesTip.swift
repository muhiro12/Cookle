import SwiftUI
import TipKit

struct StartWithRecipesTip: Tip {
    var title: Text {
        Text("Start in Recipes")
    }

    var message: Text? {
        Text("Save a recipe first, then come back here to plan breakfast, lunch, and dinner.")
    }

    var image: Image? {
        Image(systemName: "book.pages")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
