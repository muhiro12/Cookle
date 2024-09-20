//
//  RecipeFormServingSizeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormServingSizeSection: View {
    @Binding private var servingSize: String

    init(_ servingSize: Binding<String>) {
        _servingSize = servingSize
    }

    var body: some View {
        Section {
            HStack {
                TextField(text: $servingSize) {
                    Text("Serving Size")
                }
                .keyboardType(.numberPad)
                Text("servings")
            }
        } header: {
            Text("Serving Size")
        }
    }
}

#Preview {
    Form {
        RecipeFormServingSizeSection(.constant("2"))
    }
}
