//
//  RecipeFormNameSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormNameSection: View {
    @Binding private var name: String

    var body: some View {
        Section {
            TextField("Name", text: $name, prompt: Text("Spaghetti Carbonara"))
                .accessibilityValue(
                    name.isEmpty ? Text(verbatim: "") : Text(verbatim: name)
                )
        } header: {
            HStack {
                Text("Name")
                Text("*")
                    .foregroundStyle(.red)
            }
        }
    }

    init(_ name: Binding<String>) {
        _name = name
    }
}

#Preview {
    Form {
        RecipeFormNameSection(.constant("Name"))
    }
}
