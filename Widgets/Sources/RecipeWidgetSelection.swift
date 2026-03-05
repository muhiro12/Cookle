import AppIntents

enum RecipeWidgetSelection: String, AppEnum {
    case lastOpened
    case latest
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Recipe Selection")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .lastOpened: .init(title: "Last Opened"),
            .latest: .init(title: "Latest"),
            .random: .init(title: "Random")
        ]
    }
}
