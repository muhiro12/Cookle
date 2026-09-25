//
//  RecipeFormNameSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import MHUI
import SwiftUI

struct RecipeFormNameSection: View {
    @Binding private var name: String
    @FocusState private var isNameFocused: Bool

    private let showsQuickCaptureHint: Bool
    private let additionalFooter: LocalizedStringKey?

    var body: some View {
        Section {
            TextField("Name", text: $name, prompt: Text("Spaghetti Carbonara"))
                .focused($isNameFocused)
                .accessibilityValue(
                    name.isEmpty ? Text(verbatim: "") : Text(verbatim: name)
                )
                .mhRow()
        } header: {
            MHSectionHeader("Name") {
                Text("Required")
                    .mhTextStyle(.caption, colorRole: .secondaryText)
            }
        } footer: {
            if showsQuickCaptureHint {
                Text("Start with a name. Add photos, ingredients, and steps later.")
            }
            if let additionalFooter {
                Text(additionalFooter)
            }
        }
        .task {
            if showsQuickCaptureHint, name.isEmpty {
                isNameFocused = true
            }
        }
    }

    init(
        _ name: Binding<String>,
        showsQuickCaptureHint: Bool = false,
        additionalFooter: LocalizedStringKey? = nil
    ) {
        _name = name
        self.showsQuickCaptureHint = showsQuickCaptureHint
        self.additionalFooter = additionalFooter
    }
}

#Preview {
    Form {
        RecipeFormNameSection(.constant(""), showsQuickCaptureHint: true)
    }
}
