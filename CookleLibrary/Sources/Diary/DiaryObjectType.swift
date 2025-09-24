//
//  DiaryObjectType.swift
//
//
//  Created by Hiromu Nakano on 2024/05/23.
//

/// Meal kinds used in a diary.
public nonisolated enum DiaryObjectType: String, CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case dinner

    /// Localizable title key for UI sections.
    public var titleKey: String {
        switch self {
        case .breakfast:
            "Breakfasts"
        case .lunch:
            "Lunches"
        case .dinner:
            "Dinners"
        }
    }

    /// Stable identifier.
    public var id: String {
        rawValue
    }
}
