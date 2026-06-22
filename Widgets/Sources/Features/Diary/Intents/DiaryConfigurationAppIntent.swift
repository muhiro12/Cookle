import AppIntents
import WidgetKit

struct DiaryConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource {
        "Diary Configuration"
    }

    static var description: IntentDescription {
        "Configure which diary to show."
    }

    @Parameter(title: "Selection", default: .today)
    var selection: DiaryWidgetSelection
}
