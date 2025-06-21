//
//  PhotoSource.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation

enum PhotoSource: String {
    case photosPicker = "zW8rLxK4"
    case imagePlayground = "Xe1Vt9bQ"
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
