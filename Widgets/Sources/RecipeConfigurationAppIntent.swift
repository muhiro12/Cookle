import AppIntents
import WidgetKit

struct RecipeConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        "Recipe Configuration"
    }

    static var description: IntentDescription {
        "Configure which recipe to show."
    }

    @Parameter(title: "Selection", default: .lastOpened)
    var selection: RecipeWidgetSelection
}
