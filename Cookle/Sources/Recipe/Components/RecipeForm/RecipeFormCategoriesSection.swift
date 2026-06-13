//
//  RecipeFormCategoriesSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import Foundation
import SwiftData
import SwiftUI

struct RecipeFormCategoriesSection: View {
    @Binding private var categories: [String]

    @FocusState private var focusedRowID: UUID?
    @State private var categoryRowIDs: [UUID]

    var body: some View {
        Section {
            ForEach(categoryRows) { row in
                TextField(
                    "Category",
                    text: categoryBinding(at: row.index),
                    prompt: Text("Italian"),
                    axis: .vertical
                )
                .focused($focusedRowID, equals: row.id)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        if focusedRowID == row.id {
                            SuggestionButtons<Category>(
                                input: categoryBinding(at: row.index)
                            )
                        }
                    }
                }
            }
            .onDelete { offsets in
                deleteCategories(atOffsets: offsets)
            }
        } header: {
            Text("Categories")
        }
        .onAppear {
            synchronizeCategoryRowIDs()
        }
        .onChange(of: categories) {
            normalizeCategories()
            synchronizeCategoryRowIDs()
        }
    }

    init(_ categories: Binding<[String]>) {
        self._categories = categories
        self._categoryRowIDs = State(
            initialValue: RecipeFormStableRowIDs.make(
                count: categories.wrappedValue.count
            )
        )
    }
}

private extension RecipeFormCategoriesSection {
    var categoryRows: [RecipeFormStableRowIDs.IndexedRow] {
        RecipeFormStableRowIDs.indexedRows(
            rowIDs: categoryRowIDs,
            count: categories.count
        )
    }

    func categoryBinding(at index: Int) -> Binding<String> {
        .init(
            get: {
                categories[index]
            },
            set: { value in
                categories[index] = value
            }
        )
    }

    func deleteCategories(atOffsets offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        categoryRowIDs.remove(atOffsets: offsets)
        clearStaleFocus()
    }

    func normalizeCategories() {
        let normalizedCategories = RecipeFormPlaceholderRows.normalizedStrings(
            categories
        )
        guard normalizedCategories != categories else {
            return
        }

        categories = normalizedCategories
    }

    func synchronizeCategoryRowIDs() {
        RecipeFormStableRowIDs.synchronize(
            &categoryRowIDs,
            count: categories.count
        )
        clearStaleFocus()
    }

    func clearStaleFocus() {
        guard let focusedRowID,
              categoryRowIDs.contains(focusedRowID) == false else {
            return
        }

        self.focusedRowID = nil
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var categories: [Category]
    Form { () -> RecipeFormCategoriesSection in
        RecipeFormCategoriesSection(
            .constant(categories.map(\.value) + [""])
        )
    }
}
