import CookleLibrary
import WidgetKit

enum CookleWidgetReloader {
    static func reloadTodayDiaryWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.todayDiary)
    }

    static func reloadRecipeWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.randomRecipe)
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.lastOpenedRecipe)
    }

    static func reloadLastOpenedRecipeWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.lastOpenedRecipe)
    }
}
