import SwiftUI
import TipKit

struct ShortcutsTip: Tip {
    var title: Text {
        Text("Try Shortcuts")
    }

    var message: Text? {
        Text("Use Siri or Shortcuts to open recipes and settings faster.")
    }

    var image: Image? {
        Image(systemName: "waveform")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
