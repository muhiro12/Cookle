import SwiftUI
import TipKit

struct RecipeDetailTip: Tip {
    var title: Text {
        Text("Open a recipe")
    }

    var message: Text? {
        Text("Select a recipe to review ingredients, steps, photos, and related diaries.")
    }

    var image: Image? {
        Image(systemName: "doc.text.magnifyingglass")
    }

    var rules: [Rule] {
        #Rule(CookleTipEvents.didOpenRecipeDetail) { event in
            event.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
