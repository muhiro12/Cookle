import AppIntents

enum DiaryWidgetSelection: String, AppEnum {
    case today
    case latest
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Diary Selection")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .today: .init(title: "Today"),
            .latest: .init(title: "Latest"),
            .random: .init(title: "Random")
        ]
    }
}
