import MHPlatform
import SwiftUI

struct CookleSampleData: PreviewModifier {
    typealias Context = CookleAppContext

    static func makeSharedContext() -> Context {
        CookleSampleDataContext.makeSharedContext()
    }

    func body(content: Content, context: Context) -> some View {
        content
            .cookleAppContext(context)
    }
}
