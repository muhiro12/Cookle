//
//  CookleGoogleMobileAds.swift
//
//
//  Created by Hiromu Nakano on 2024/06/04.
//

import SwiftUI

@Observable
final class CookleGoogleMobileAds {
    private let builder: (String) -> AnyView

    init(builder: @escaping (String) -> some View) {
        self.builder = {
            .init(builder($0))
        }
    }

    func callAsFunction(_ id: String) -> some View {
        builder(id)
    }
}

public extension View {
    func googleMobileAds(_ builder: @escaping (String) -> some View) -> some View {
        environment(CookleGoogleMobileAds(builder: builder))
    }
}
