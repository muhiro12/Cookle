//
//  RecipeFormCookingTimeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormCookingTimeSection: View {
    @Binding private var cookingTime: String

    var body: some View {
        Section {
            HStack {
                TextField(text: $cookingTime) {
                    Text("30")
                }
                .keyboardType(.numberPad)
                Text("minutes")
            }
        } header: {
            Text("Cooking Time")
        }
    }

    init(_ cookingTime: Binding<String>) {
        _cookingTime = cookingTime
    }
}

#Preview {
    Form {
        RecipeFormCookingTimeSection(.constant("30"))
    }
}
