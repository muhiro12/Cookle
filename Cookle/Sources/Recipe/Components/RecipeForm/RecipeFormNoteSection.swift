//
//  RecipeFormNoteSection.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct RecipeFormNoteSection: View {
    @Binding private var note: String

    var body: some View {
        Section {
            TextField(text: $note, axis: .vertical) {
                Text("Use freshly grated Parmesan for the best flavor.")
            }
        } header: {
            Text("Note")
        }
    }

    init(_ note: Binding<String>) {
        _note = note
    }
}

#Preview {
    Form {
        RecipeFormNoteSection(.constant("Note"))
    }
}
