//
//  AppIntent.swift
//  Widgets
//
//  Created by Hiromu Nakano on 2025/09/25.
//

import AppIntents
import WidgetKit

enum DiaryWidgetMode: String, AppEnum {
    case latest
    case today
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Diary Mode")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .latest: .init(title: "Latest"),
            .today: .init(title: "Today"),
            .random: .init(title: "Random")
        ]
    }
}

struct DiaryConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Diary Configuration" }
    static var description: IntentDescription { "Configure which diary to show." }

    @Parameter(title: "Mode", default: .today)
    var mode: DiaryWidgetMode
}

enum RecipeWidgetMode: String, AppEnum {
    case latest
    case lastOpened
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Recipe Mode")
    }

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] {
        [
            .latest: .init(title: "Latest"),
            .lastOpened: .init(title: "Last Opened"),
            .random: .init(title: "Random")
        ]
    }
}

struct RecipeConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Recipe Configuration" }
    static var description: IntentDescription { "Configure which recipe to show." }

    @Parameter(title: "Mode", default: .random)
    var mode: RecipeWidgetMode
}
