import CookleLibrary
import WidgetKit

enum CookleWidgetReloader {
    static func reloadTodayDiaryWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.todayDiary)
    }

    static func reloadRecipeWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.recipe)
    }

    static func reloadRecipeWidgets() {
        reloadRecipeWidget()
    }

    static func reloadLastOpenedRecipeWidget() {
        reloadRecipeWidget()
    }
}
