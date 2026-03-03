//
//  RecipeFormServingSizeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormServingSizeSection: View {
    @Binding private var servingSize: String

    var body: some View {
        Section {
            HStack {
                TextField(text: $servingSize) {
                    Text("2")
                }
                .keyboardType(.numberPad)
                Text("servings")
            }
        } header: {
            Text("Serving Size")
        }
    }

    init(_ servingSize: Binding<String>) {
        _servingSize = servingSize
    }
}

#Preview {
    Form {
        RecipeFormServingSizeSection(.constant("2"))
    }
}
