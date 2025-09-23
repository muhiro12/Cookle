@testable import CookleLibrary
import Testing

@Suite("SubObject")
struct SubObjectTests {
    @Test("Orders objects using their order property")
    func comparableUsesOrder() {
        let lower: MockSubObject = .init(order: 1)
        let higher: MockSubObject = .init(order: 2)

        #expect(lower < higher)
        #expect([higher, lower].sorted() == [lower, higher])
    }
}

private struct MockSubObject: SubObject {
    let order: Int

    init(order: Int) {
        self.order = order
    }
}
