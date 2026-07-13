@testable import CookleLibrary
import Testing

struct DeduplicatedModelCreationTests {
    private enum TestError: Error, Equatable {
        case fetchFailed
    }

    @Test
    func resolve_reusesExistingModelWithoutCreatingFallback() {
        var didCreateFallback = false

        let value = DeduplicatedModelCreation.resolve {
            1
        } createNew: {
            didCreateFallback = true
            return 2
        }

        #expect(value == 1)
        #expect(didCreateFallback == false)
    }

    @Test
    func resolve_propagatesFetchFailureWithoutCreatingFallback() {
        var didCreateFallback = false

        #expect(throws: TestError.fetchFailed) {
            _ = try DeduplicatedModelCreation.resolve {
                () throws -> Int? in
                throw TestError.fetchFailed
            } createNew: {
                didCreateFallback = true
                return 1
            }
        }

        #expect(didCreateFallback == false)
    }
}
