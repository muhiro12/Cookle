//
//  RecipeCreateView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import SwiftUI
import SwiftData

struct RecipeCreateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Environment(TagStore.self) private var tagStore

    @State private var name = ""
    @State private var imageList = [Data]()
    @State private var ingredientList = [""]
    @State private var instructionList = [""]
    @State private var tagList = [""]

    var body: some View {
        NavigationView {
            Form {
                Section("Name") {
                    ZStack(alignment: .trailing) {
                        TextField("Name", text: $name)
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                Section("Images") {
                    ForEach(imageList, id: \.self) {
                        if let image = UIImage(data: $0) {
                            Image(uiImage: image)
                        }
                    }
                }
                MultiAddableSection(data: $ingredientList,
                                    title: "Ingredients",
                                    tagList: tagStore.tags.filter { $0.type == .ingredient },
                                    shouldShowNumber: false)
                MultiAddableSection(data: $instructionList,
                                    title: "Instructions",
                                    tagList: tagStore.tags.filter { $0.type == .instruction },
                                    shouldShowNumber: true)
                MultiAddableSection(data: $tagList,
                                    title: "Tags",
                                    tagList: tagStore.tags.filter { $0.type == .custom },
                                    shouldShowNumber: false)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        modelContext.insert(
                            Recipe(
                                name: name,
                                imageList: imageList,
                                ingredientList: ingredientList.filter { !$0.isEmpty },
                                instructionList: instructionList.filter { !$0.isEmpty },
                                tagList: tagList.filter { !$0.isEmpty }
                            )
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    RecipeCreateView()
        .environment(PreviewData.tagStore)
}
