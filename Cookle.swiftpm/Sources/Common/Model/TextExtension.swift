//
//  TextExtension.swift
//
//
//  Created by Hiromu Nakano on 2024/07/04.
//

import SwiftUI

extension Text {
    init(_ key: LocalizedStringKey) {
        self.init(key, bundle: .module)
    }
}
