@testable import CookleLibrary
import Testing

struct RecipeBrowseSortSelectionTests {
    private struct SelectionExpectation {
        let selection: RecipeBrowseSortSelection
        let sortMode: RecipeBrowseSortMode
        let isAscending: Bool

        init(
            _ selection: RecipeBrowseSortSelection,
            _ sortMode: RecipeBrowseSortMode,
            _ isAscending: Bool
        ) {
            self.selection = selection
            self.sortMode = sortMode
            self.isAscending = isAscending
        }
    }

    @Test
    func selection_roundTripsSortModeAndDirection() {
        let cases: [SelectionExpectation] = [
            .init(.alphabeticalAscending, .alphabetical, true),
            .init(.alphabeticalDescending, .alphabetical, false),
            .init(.recentlyCreatedAscending, .recentlyCreated, true),
            .init(.recentlyCreatedDescending, .recentlyCreated, false),
            .init(.madeCountAscending, .madeCount, true),
            .init(.madeCountDescending, .madeCount, false)
        ]

        for expectation in cases {
            #expect(expectation.selection.sortMode == expectation.sortMode)
            #expect(expectation.selection.isAscending == expectation.isAscending)
            #expect(
                RecipeBrowseSortSelection(
                    sortMode: expectation.sortMode,
                    isAscending: expectation.isAscending
                ) == expectation.selection
            )
        }
    }
}
