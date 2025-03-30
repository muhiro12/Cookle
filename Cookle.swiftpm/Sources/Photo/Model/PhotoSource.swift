//
//  PhotoSource.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation

enum PhotoSource {
    case photosPicker
    case imagePlayground
}

extension PhotoSource {
    static let defaultValue = PhotoSource.photosPicker

    var description: String {
        switch self {
        case .photosPicker:
            return "Photos"
        case .imagePlayground:
            return "Image Playground"
        }
    }
}

extension PhotoSource: Codable {}
