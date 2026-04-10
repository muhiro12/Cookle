import Testing

@testable import Cookle

@MainActor
struct DebugSidebarViewTests {
    @Test
    func diagnosticDestinations_includeLogs() {
        let view = DebugSidebarView()

        #expect(view.diagnosticDestinations.contains { destination in
            destination.content == .logs
        })
    }
}
