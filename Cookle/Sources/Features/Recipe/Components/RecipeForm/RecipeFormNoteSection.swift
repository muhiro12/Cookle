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
            TextField(
                "Note",
                text: $note,
                prompt: Text("Use freshly grated Parmesan for the best flavor."),
                axis: .vertical
            )
            .accessibilityValue(
                note.isEmpty ? Text(verbatim: "") : Text(verbatim: note)
            )
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
