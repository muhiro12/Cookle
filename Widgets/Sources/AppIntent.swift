//
//  AppIntent.swift
//  Widgets
//
//  Created by Hiromu Nakano on 2025/09/25.
//

import AppIntents
import WidgetKit

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

struct DiaryConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Diary Configuration" }
    static var description: IntentDescription { "Configure which diary to show." }

    @Parameter(title: "Selection", default: .today)
    var selection: DiaryWidgetSelection
}

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

struct RecipeConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Recipe Configuration" }
    static var description: IntentDescription { "Configure which recipe to show." }

    @Parameter(title: "Selection", default: .lastOpened)
    var selection: RecipeWidgetSelection
}
