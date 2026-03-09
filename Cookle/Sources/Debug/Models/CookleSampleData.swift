import SwiftUI

struct CookleSampleData: PreviewModifier {
    typealias Context = CooklePlatformEnvironment

    static func makeSharedContext() -> Context {
        CookleSampleDataContext.makeSharedContext()
    }

    func body(content: Content, context: Context) -> some View {
        content
            .cooklePlatformEnvironment(context)
    }
}
