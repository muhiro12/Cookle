//
//  RecipeFormNameSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormNameSection: View {
    @Binding private var name: String

    init(_ name: Binding<String>) {
        _name = name
    }

    var body: some View {
        Section {
            TextField(text: $name) {
                Text("Name")
            }
        } header: {
            HStack {
                Text("Name")
                Text("*")
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    Form {
        RecipeFormNameSection(.constant("Name"))
    }
}
