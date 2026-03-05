import SwiftUI
import TipKit

struct AddRecipeTip: Tip {
    var title: Text {
        Text("Add your first recipe")
    }

    var message: Text? {
        Text("Save ingredients, steps, photos, and notes in one place.")
    }

    var image: Image? {
        Image(systemName: "square.and.pencil")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
