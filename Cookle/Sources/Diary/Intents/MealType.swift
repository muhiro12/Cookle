import AppIntents

enum MealType: String, AppEnum {
    case breakfast
    case lunch
    case dinner

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Meal Type")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .breakfast: .init(title: "Breakfast"),
            .lunch: .init(title: "Lunch"),
            .dinner: .init(title: "Dinner")
        ]
    }
}

extension MealType {
    var diaryType: DiaryObjectType {
        switch self {
        case .breakfast: .breakfast
        case .lunch: .lunch
        case .dinner: .dinner
        }
    }
}
