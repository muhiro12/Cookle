//
//  ToggleListStyleButton.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/13.
//

import SwiftUI

struct ToggleListStyleButton: View {
    @Binding var isGrid: Bool

    var body: some View {
        Button("Toggle Style", systemImage: isGrid ? "list.bullet" : "square.grid.3x3") {
            isGrid.toggle()
        }
    }
}

#Preview {
    ToggleListStyleButton(isGrid: .constant(true))
}
