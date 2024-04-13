//
//  InMemoryContextEnvironmentKey.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/14.
//

import SwiftUI

struct InMemoryContextEnvironmentKey: EnvironmentKey {
    typealias Value = InMemoryContext
    static var defaultValue: InMemoryContext = .init()
}
