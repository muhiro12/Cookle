//
//  EnvironmentValuesExtension.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftUI

extension EnvironmentValues {
    var inMemoryContext: InMemoryContext {
        get { self[InMemoryContextEnvironmentKey.self] }
        set { self[InMemoryContextEnvironmentKey.self] = newValue }
    }
}
