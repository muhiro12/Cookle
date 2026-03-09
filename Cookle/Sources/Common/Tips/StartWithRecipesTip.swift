import SwiftUI
import TipKit

struct StartWithRecipesTip: Tip {
    var title: Text {
        Text("Open Recipes first")
    }

    var message: Text? {
        Text("Save a recipe, then come back here to plan meals.")
    }

    var image: Image? {
        Image(systemName: "book.pages")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
