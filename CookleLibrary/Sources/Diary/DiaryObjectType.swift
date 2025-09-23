//
//  DiaryObjectType.swift
//
//
//  Created by Hiromu Nakano on 2024/05/23.
//

public nonisolated enum DiaryObjectType: String, CaseIterable, Codable, Identifiable {
    case breakfast
    case lunch
    case dinner

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

    public var id: String {
        rawValue
    }
}
