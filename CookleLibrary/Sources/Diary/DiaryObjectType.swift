//
//  DiaryObjectType.swift
//
//
//  Created by Hiromu Nakano on 2024/05/23.
//

import SwiftUI

/// Meal kinds used in a diary.
public nonisolated enum DiaryObjectType: CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case dinner

    /// Localized title used for display.
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

    /// Stable string identifier for this case.
    public var id: String {
        .init(describing: self)
    }
}
