//
//  TitleAndLargeIconLabelStyle.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/1/24.
//

import SwiftUI

struct TitleAndLargeIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.icon
                .frame(width: 64)
                .padding()
            configuration.title
        }
    }
}

extension LabelStyle where Self == TitleAndLargeIconLabelStyle {
    static var titleAndLargeIcon: TitleAndLargeIconLabelStyle {
        .init()
    }
}
