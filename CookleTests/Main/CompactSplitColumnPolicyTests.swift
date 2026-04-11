import SwiftUI
import Testing

@testable import Cookle

@MainActor
struct CompactSplitColumnPolicyTests {
    @Test
    func twoColumn_withoutDetailSelection_prefersSidebar() {
        let column = CompactSplitColumnPolicy.twoColumn(
            hasDetailSelection: false
        )

        #expect(column == .sidebar)
    }

    @Test
    func twoColumn_withDetailSelection_prefersDetail() {
        let column = CompactSplitColumnPolicy.twoColumn(
            hasDetailSelection: true
        )

        #expect(column == .detail)
    }

    @Test
    func threeColumn_withoutSelections_prefersSidebar() {
        let column = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: false,
            hasDetailSelection: false
        )

        #expect(column == .sidebar)
    }

    @Test
    func threeColumn_withContentSelectionOnly_prefersContent() {
        let column = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: true,
            hasDetailSelection: false
        )

        #expect(column == .content)
    }

    @Test
    func threeColumn_withDetailSelection_prefersDetail() {
        let column = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: true,
            hasDetailSelection: true
        )

        #expect(column == .detail)
    }

    @Test
    func threeColumn_withDiagnosticContentOnly_prefersContent() {
        let column = CompactSplitColumnPolicy.threeColumn(
            hasContentSelection: true,
            hasDetailSelection: false
        )

        #expect(column == .content)
    }
}
