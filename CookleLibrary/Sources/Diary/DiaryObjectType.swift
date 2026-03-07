//
//  DiaryObjectType.swift
//
//
//  Created by Hiromu Nakano on 2024/05/23.
//

import SwiftUI

/// Stable meal sections used to organize diary rows and section titles.
nonisolated public enum DiaryObjectType: CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case dinner

    /// Localized section title shown for this meal type in the UI.
    public var title: LocalizedStringKey {
        switch self {
        case .breakfast:
            "Breakfasts"
        case .lunch:
            "Lunches"
        case .dinner:
            "Dinners"
        }
    }

    /// Stable identifier derived from the case name for lists and persistence helpers.
    public var id: String {
        .init(describing: self)
    }
}
