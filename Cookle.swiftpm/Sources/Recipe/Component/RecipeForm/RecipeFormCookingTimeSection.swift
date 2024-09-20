//
//  RecipeFormCookingTimeSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormCookingTimeSection: View {
    @Binding private var cookingTime: String

    init(_ cookingTime: Binding<String>) {
        _cookingTime = cookingTime
    }

    var body: some View {
        Section {
            HStack {
                TextField(text: $cookingTime) {
                    Text("Cooking Time")
                }
                .keyboardType(.numberPad)
                Text("minutes")
            }
        } header: {
            Text("Cooking Time")
        }
    }
}

#Preview {
    Form {
        RecipeFormCookingTimeSection(.constant("30"))
    }
}
