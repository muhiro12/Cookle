import SwiftUI
import TipKit

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
        #Rule(CookleTipEvents.didOpenDiaryForm) { event in
            event.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
