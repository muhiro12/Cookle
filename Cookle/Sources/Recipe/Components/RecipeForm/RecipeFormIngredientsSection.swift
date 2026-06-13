//
//  RecipeFormIngredientsSection.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/05/03.
//

import Foundation
import SwiftData
import SwiftUI

typealias RecipeFormIngredient = RecipeFormIngredientInput

struct RecipeFormIngredientsSection: View {
    @Binding private var ingredients: [RecipeFormIngredient]

    @FocusState private var focusedRowID: UUID?
    @State private var ingredientRowIDs: [UUID]

    var body: some View {
        Section {
            ForEach(ingredientRows) { row in
                ingredientRow(for: row)
                    .toolbar {
                        ingredientSuggestionToolbarItem(for: row)
                    }
            }
            .onMove { sourceOffsets, destinationOffset in
                moveIngredients(
                    fromOffsets: sourceOffsets,
                    toOffset: destinationOffset
                )
            }
            .onDelete { offsets in
                deleteIngredients(atOffsets: offsets)
            }
        } header: {
            HStack {
                Text("Ingredients")
                Spacer()
                AddMultipleIngredientsButton(ingredients: $ingredients)
                    .font(.caption)
                    .textCase(nil)
            }
        }
        .onAppear {
            synchronizeIngredientRowIDs()
        }
        .onChange(of: ingredients) {
            normalizeIngredients()
            synchronizeIngredientRowIDs()
        }
    }

    init(_ ingredients: Binding<[RecipeFormIngredient]>) {
        self._ingredients = ingredients
        self._ingredientRowIDs = State(
            initialValue: RecipeFormStableRowIDs.make(
                count: ingredients.wrappedValue.count
            )
        )
    }
}

private extension RecipeFormIngredientsSection {
    var ingredientRows: [RecipeFormStableRowIDs.IndexedRow] {
        RecipeFormStableRowIDs.indexedRows(
            rowIDs: ingredientRowIDs,
            count: ingredients.count
        )
    }

    func ingredientRow(
        for row: RecipeFormStableRowIDs.IndexedRow
    ) -> some View {
        HStack(alignment: .top) {
            TextField(
                "Ingredient",
                text: ingredientNameBinding(at: row.index),
                prompt: Text("Spaghetti"),
                axis: .vertical
            )
            .focused($focusedRowID, equals: row.id)
            TextField(
                "Amount",
                text: ingredientAmountBinding(at: row.index),
                prompt: Text("200g")
            )
            .multilineTextAlignment(.trailing)
        }
    }

    @ToolbarContentBuilder
    func ingredientSuggestionToolbarItem(
        for row: RecipeFormStableRowIDs.IndexedRow
    ) -> some ToolbarContent {
        ToolbarItem(placement: .keyboard) {
            if focusedRowID == row.id {
                SuggestionButtons<Ingredient>(
                    input: ingredientNameBinding(at: row.index)
                )
            }
        }
    }

    func ingredientNameBinding(at index: Int) -> Binding<String> {
        .init(
            get: {
                ingredients[index].ingredient
            },
            set: { value in
                ingredients[index].ingredient = value
            }
        )
    }

    func ingredientAmountBinding(at index: Int) -> Binding<String> {
        .init(
            get: {
                ingredients[index].amount
            },
            set: { value in
                ingredients[index].amount = value
            }
        )
    }

    func moveIngredients(
        fromOffsets sourceOffsets: IndexSet,
        toOffset destinationOffset: Int
    ) {
        ingredients.move(
            fromOffsets: sourceOffsets,
            toOffset: destinationOffset
        )
        ingredientRowIDs.move(
            fromOffsets: sourceOffsets,
            toOffset: destinationOffset
        )
    }

    func deleteIngredients(atOffsets offsets: IndexSet) {
        ingredients.remove(atOffsets: offsets)
        ingredientRowIDs.remove(atOffsets: offsets)
        clearStaleFocus()
    }

    func normalizeIngredients() {
        let normalizedIngredients = RecipeFormPlaceholderRows.normalizedIngredients(
            ingredients
        )
        guard normalizedIngredients != ingredients else {
            return
        }

        ingredients = normalizedIngredients
    }

    func synchronizeIngredientRowIDs() {
        RecipeFormStableRowIDs.synchronize(
            &ingredientRowIDs,
            count: ingredients.count
        )
        clearStaleFocus()
    }

    func clearStaleFocus() {
        guard let focusedRowID,
              ingredientRowIDs.contains(focusedRowID) == false else {
            return
        }

        self.focusedRowID = nil
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    Form { () -> RecipeFormIngredientsSection in
        let previewIngredients: [RecipeFormIngredient] = recipes[0].ingredientObjects?.compactMap { ingredientObject in
            guard let ingredient = ingredientObject.ingredient else {
                return nil
            }
            return RecipeFormIngredient(
                ingredient: ingredient.value,
                amount: ingredientObject.amount
            )
        } ?? []
        RecipeFormIngredientsSection(
            .constant(
                previewIngredients
                    + [.init(ingredient: "", amount: "")]
            )
        )
    }
}
