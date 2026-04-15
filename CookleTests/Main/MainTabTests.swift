import Testing

@testable import Cookle

@MainActor
struct MainTabTests {
    @Test
    func displayedTabs_forCompactWidth_matchExpectedOrder() {
        #expect(
            MainTab.displayedTabs(
                isRegularWidth: false,
                isDebugOn: false
            ) == [
                .diary,
                .recipe,
                .photo,
                .settings,
                .search
            ]
        )
    }

    @Test
    func displayedTabs_forRegularWidth_matchExpectedOrder() {
        #expect(
            MainTab.displayedTabs(
                isRegularWidth: true,
                isDebugOn: false
            ) == [
                .diary,
                .recipe,
                .photo,
                .settings,
                .search
            ]
        )
    }

    @Test
    func displayedTabs_forRegularWidthAndDebugOn_appendsDebug() {
        #expect(
            MainTab.displayedTabs(
                isRegularWidth: true,
                isDebugOn: true
            ) == [
                .diary,
                .recipe,
                .photo,
                .settings,
                .search,
                .debug
            ]
        )
    }
}
