import SwiftUI
import TipKit

struct ImagePlaygroundTip: Tip {
    var title: Text {
        Text("Generate a dish image")
    }

    var message: Text? {
        Text("Use Image Playground when you do not have a photo yet.")
    }

    var image: Image? {
        Image(systemName: "apple.image.playground")
    }

    var options: [any TipOption] {
        Tips.MaxDisplayCount(1)
    }
}
