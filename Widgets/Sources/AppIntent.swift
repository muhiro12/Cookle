//
//  AppIntent.swift
//  Widgets
//
//  Created by Hiromu Nakano on 2025/09/25.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Cookle widgets configuration." }
}
