//
//  RecipeFormNameSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormNameSection: View {
    @Binding private var name: String

    private let showsQuickCaptureHint: Bool

    var body: some View {
        Section {
            TextField("Name", text: $name, prompt: Text("Spaghetti Carbonara"))
                .accessibilityValue(
                    name.isEmpty ? Text(verbatim: "") : Text(verbatim: name)
                )
        } header: {
            HStack {
                Text("Name")
                Text("Required")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        } footer: {
            if showsQuickCaptureHint {
                Text("Start with a name. Add photos, ingredients, and steps later.")
            }
        }
    }

    init(_ name: Binding<String>, showsQuickCaptureHint: Bool = false) {
        _name = name
        self.showsQuickCaptureHint = showsQuickCaptureHint
    }
}

#Preview {
    Form {
        RecipeFormNameSection(.constant(""), showsQuickCaptureHint: true)
    }
}
