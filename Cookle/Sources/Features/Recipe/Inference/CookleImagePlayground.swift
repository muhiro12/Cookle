//
//  CookleImagePlayground.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/30.
//

import AppIntents
import Foundation
import ImagePlayground
import SwiftUI

enum CookleImagePlayground {
    static var isSupported: Bool {
        if #available(iOS 18.1, *) {
            EnvironmentValues().supportsImagePlayground
        } else {
            false
        }
    }
}

extension View {
    @ViewBuilder
    func cookleImagePlayground(
        isPresented: Binding<Bool>,
        recipe: Recipe?,
        onCompletion: @escaping (Data) -> Void,
        onCancellation: (() -> Void)? = nil
    ) -> some View {
        if #available(iOS 18.1, *) {
            modifier(
                CookleImagePlaygroundModifier(
                    isPresented: isPresented,
                    recipe: recipe,
                    onCompletion: onCompletion,
                    onCancellation: onCancellation
                )
            )
        } else {
            self
        }
    }
}
