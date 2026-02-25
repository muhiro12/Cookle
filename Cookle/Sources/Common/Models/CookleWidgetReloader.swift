import CookleLibrary
import WidgetKit

enum CookleWidgetReloader {
    static func reloadDiaryWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: CookleWidgetKind.diary)
    }

    static func reloadTodayDiaryWidget() {
        reloadDiaryWidget()
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
