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
        #Rule(CookleTipEvents.didOpenRecipeDetail) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}

struct AddDiaryTip: Tip {
    var title: Text {
        Text("Plan meals with diaries")
    }

    var message: Text? {
        Text("Pick saved recipes for breakfast, lunch, and dinner to keep a daily meal log.")
    }

    var image: Image? {
        Image(systemName: "calendar")
    }

    var rules: [Rule] {
        #Rule(CookleTipEvents.didOpenDiaryForm) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}

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

struct SubscriptionTip: Tip {
    var title: Text {
        Text("Explore Premium")
    }

    var message: Text? {
        Text("Open Subscription to unlock iCloud sync and remove ads across the app.")
    }

    var image: Image? {
        Image(systemName: "star.circle")
    }

    var rules: [Rule] {
        #Rule(CookleTipEvents.didOpenSubscription) {
            $0.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
