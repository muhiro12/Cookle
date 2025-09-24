//
//  PhotoSource.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation

/// Source where a photo was obtained.
public nonisolated enum PhotoSource: String, Sendable {
    case photosPicker = "zW8rLxK4"
    case imagePlayground = "Xe1Vt9bQ"
}

public extension PhotoSource {
    /// Default photo source used when none is specified.
    static let defaultValue = PhotoSource.photosPicker

    /// Human-friendly source name for UI.
    var description: String {
        switch self {
        case .photosPicker:
            return "Photos"
        case .imagePlayground:
            return "Image Playground"
        }
    }
}
