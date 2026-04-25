@testable import CookleLibrary
import Testing

struct RecipeBrowseSortSelectionTests {
    @Test
    func selection_roundTripsSortModeAndDirection() {
        let cases: [(RecipeBrowseSortSelection, RecipeBrowseSortMode, Bool)] = [
            (.alphabeticalAscending, .alphabetical, true),
            (.alphabeticalDescending, .alphabetical, false),
            (.recentlyCreatedAscending, .recentlyCreated, true),
            (.recentlyCreatedDescending, .recentlyCreated, false),
            (.madeCountAscending, .madeCount, true),
            (.madeCountDescending, .madeCount, false)
        ]

        for (selection, sortMode, isAscending) in cases {
            #expect(selection.sortMode == sortMode)
            #expect(selection.isAscending == isAscending)
            #expect(
                RecipeBrowseSortSelection(
                    sortMode: sortMode,
                    isAscending: isAscending
                ) == selection
            )
        }
    }
}
