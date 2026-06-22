import SwiftUI
import TipKit

struct AddDiaryTip: Tip {
    var title: Text {
        Text("Add your first diary")
    }

    var message: Text? {
        Text("Pick saved recipes for breakfast, lunch, and dinner.")
    }

    var image: Image? {
        Image(systemName: "calendar")
    }

    var rules: [Rule] {
        #Rule(CookleTipEvents.didOpenDiaryForm) { event in
            event.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
