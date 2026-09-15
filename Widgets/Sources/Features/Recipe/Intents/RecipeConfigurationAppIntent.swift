import AppIntents
import WidgetKit

struct RecipeConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        "Recipe Configuration"
    }

    static var description: IntentDescription {
        "Configure which recipe to show."
    }

    static var parameterSummary: some ParameterSummary {
        When(\.$selection, .equalTo, .selected) {
            Summary {
                \.$selection
                \.$recipe
            }
        } otherwise: {
            Summary {
                \.$selection
            }
        }
    }

    @Parameter(title: "Selection", default: .lastOpened)
    var selection: RecipeWidgetSelection

    @Parameter(title: "Recipe")
    var recipe: RecipeWidgetEntity?
}
