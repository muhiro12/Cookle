import SwiftUI
import TipKit

struct AddRecipeTip: Tip {
    var title: Text {
        Text("Save a recipe")
    }

    var message: Text? {
        Text("Keep ingredients, steps, photos, and notes together.")
    }

    var image: Image? {
        Image(systemName: "square.and.pencil")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
