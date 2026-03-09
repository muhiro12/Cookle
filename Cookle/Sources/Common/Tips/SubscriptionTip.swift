import SwiftUI
import TipKit

struct SubscriptionTip: Tip {
    var title: Text {
        Text("Enable Premium features")
    }

    var message: Text? {
        Text("Open Subscription to turn on iCloud sync and hide ads.")
    }

    var image: Image? {
        Image(systemName: "star.circle")
    }

    var rules: [Rule] {
        #Rule(CookleTipEvents.didOpenSubscription) { event in
            event.donations.count == 0
        }
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
