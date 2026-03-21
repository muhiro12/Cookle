import SwiftUI

struct CookleSampleData: PreviewModifier {
    typealias Context = CookleAppAssembly

    static func makeSharedContext() -> Context {
        CookleSampleDataContext.makeSharedContext()
    }

    func body(content: Content, context: Context) -> some View {
        content
            .cooklePreviewAppAssembly(context)
    }
}
