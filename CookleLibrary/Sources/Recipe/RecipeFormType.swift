//
//  RecipeFormType.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 10/18/24.
//

/// Describes how the recipe form should behave.
public enum RecipeFormType {
    /// Creates a new recipe.
    case create
    /// Edits an existing recipe.
    case edit
    /// Duplicates an existing recipe into a new draft.
    case duplicate
}
