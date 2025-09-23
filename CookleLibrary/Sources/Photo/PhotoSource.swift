//
//  PhotoSource.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation

public nonisolated enum PhotoSource: String {
    case photosPicker = "zW8rLxK4"
    case imagePlayground = "Xe1Vt9bQ"
}

public extension PhotoSource {
    public static let defaultValue = PhotoSource.photosPicker

    public var description: String {
        switch self {
        case .photosPicker:
            return "Photos"
        case .imagePlayground:
            return "Image Playground"
        }
    }
}
