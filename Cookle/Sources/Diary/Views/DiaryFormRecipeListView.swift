//
//  DiaryFormRecipeListView.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/30/24.
//

import SwiftData
import SwiftUI
import SwiftUtilities

struct DiaryFormRecipeListView: View {
    @Environment(\.dismiss) private var dismiss

    @BridgeQuery(.init(.recipes(.all))) private var recipes: [RecipeEntity]

    @Binding private var selection: Set<RecipeEntity>

    @State private var temporarySelection = Set<RecipeEntity>()
    @State private var searchText = ""

    private let type: DiaryObjectType

    init(selection: Binding<Set<RecipeEntity>> = .constant([]), type: DiaryObjectType) {
        _selection = selection
        _temporarySelection = .init(initialValue: selection.wrappedValue)
        self.type = type
    }

    var body: some View {
        List(
            recipes.filter {
                guard !searchText.isEmpty else {
                    return true
                }
                return $0.name.normalizedContains(searchText)
            },
            selection: $temporarySelection
        ) { recipe in
            RecipeLabel()
                .labelStyle(.titleAndLargeIcon)
                .tag(recipe)
                .environment(recipe)
        }
        .searchable(text: $searchText)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(type.title)
        .toolbar {
            ToolbarItem {
                Button {
                    selection = temporarySelection
                    dismiss()
                } label: {
                    Text("Done")
                }
            }
        }
    }
}

#Preview {
    CooklePreview { _ in
        NavigationStack {
            DiaryFormRecipeListView(type: .dinner)
        }
    }
}
