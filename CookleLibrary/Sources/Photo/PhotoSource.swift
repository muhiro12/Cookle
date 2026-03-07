//
//  PhotoSource.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation

/// Origin of a photo asset stored with a recipe.
nonisolated public enum PhotoSource: String, Sendable {
    case photosPicker = "zW8rLxK4"
    case imagePlayground = "Xe1Vt9bQ"
}

public extension PhotoSource {
    /// Fallback source used when persisted data is missing or cannot be decoded.
    static let defaultValue = PhotoSource.photosPicker

    /// User-facing label shown when presenting the asset origin.
    var description: String {
        switch self {
        case .photosPicker:
            return "Photos"
        case .imagePlayground:
            return "Image Playground"
        }
    }
}
