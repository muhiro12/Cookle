//
//  PhotoData.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation

public struct PhotoData: Sendable {
    public let data: Data
    public let source: PhotoSource

    public init(data: Data, source: PhotoSource) {
        self.data = data
        self.source = source
    }
}
