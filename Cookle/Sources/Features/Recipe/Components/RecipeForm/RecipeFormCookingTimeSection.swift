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
                TextField("Cooking Time", text: $cookingTime, prompt: Text("30"))
                    .keyboardType(.numberPad)
                    .accessibilityValue(
                        cookingTime.isEmpty ? Text(verbatim: "") : Text(verbatim: cookingTime)
                    )
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
