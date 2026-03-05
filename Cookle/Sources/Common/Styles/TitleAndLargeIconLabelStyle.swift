//
//  TitleAndLargeIconLabelStyle.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/1/24.
//

import SwiftUI

struct TitleAndLargeIconLabelStyle: LabelStyle {
    private enum Layout {
        static let iconWidth = CGFloat(Int("80") ?? .zero)
    }

    func makeBody(configuration: LabelStyleConfiguration) -> some View {
        HStack {
            configuration.icon
                .frame(width: Layout.iconWidth)
            configuration.title
                .padding(.leading)
        }
    }
}

extension LabelStyle where Self == TitleAndLargeIconLabelStyle {
    static var titleAndLargeIcon: TitleAndLargeIconLabelStyle {
        .init()
    }
}
