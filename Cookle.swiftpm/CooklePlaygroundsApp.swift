import SwiftUI

@main
struct CooklePlaygroundsApp: App {
    @AppStorage(.isDebugOn) private var isDebugOn

    var body: some Scene {
        WindowGroup {
            ContentView()
                .cooklePlaygroundsEnvironment()
                .task {
                    isDebugOn = true
                }
        }
    }
}
