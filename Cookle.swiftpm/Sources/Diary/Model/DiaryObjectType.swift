//
//  DiaryObjectType.swift
//
//
//  Created by Hiromu Nakano on 2024/05/23.
//

import SwiftUI

enum DiaryObjectType: Codable {
    case breakfast
    case lunch
    case dinner

    var title: LocalizedStringKey {
        switch self {
        case .breakfast:
            "Breakfasts"
        case .lunch:
            "Lunches"
        case .dinner:
            "Dinners"
        }
    }
}
