//
//  AppIntent.swift
//  Widgets
//
//  Created by Hiromu Nakano on 2025/09/25.
//

import AppIntents
import WidgetKit

enum DiaryWidgetMode: String, AppEnum {
    case today
    case latest
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Diary Mode")
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

    @Parameter(title: "Mode", default: .today)
    var mode: DiaryWidgetMode
}

enum RecipeWidgetMode: String, AppEnum {
    case lastOpened
    case latest
    case random

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        .init(name: "Recipe Mode")
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

    @Parameter(title: "Mode", default: .lastOpened)
    var mode: RecipeWidgetMode
}
