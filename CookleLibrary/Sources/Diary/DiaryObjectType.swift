//
//  DiaryObjectType.swift
//
//
//  Created by Hiromu Nakano on 2024/05/23.
//

import SwiftUI

/// Meal kinds used in a diary.
public nonisolated enum DiaryObjectType: String, CaseIterable, Codable, Identifiable {
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

extension DiaryObjectType {
    private struct CodingKey: Swift.CodingKey {
        let stringValue: String
        let intValue: Int? = .none

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            _ = intValue
            return nil
        }
    }

    public init(from decoder: any Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let rawValue = try? container.decode(String.self),
           let value = Self(rawValue: rawValue) {
            self = value
            return
        }

        let container = try decoder.container(keyedBy: CodingKey.self)
        if container.allKeys.count == 1,
           let firstKey = container.allKeys.first,
           let value = Self(rawValue: firstKey.stringValue) {
            self = value
            return
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: decoder.codingPath,
                debugDescription: "Unsupported DiaryObjectType payload"
            )
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
