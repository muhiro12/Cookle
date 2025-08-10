@testable import Cookle
import Testing

@MainActor
struct MainServiceTests {
    @Test
    func open_does_not_throw() throws {
        try MainService.open()
    }
}

