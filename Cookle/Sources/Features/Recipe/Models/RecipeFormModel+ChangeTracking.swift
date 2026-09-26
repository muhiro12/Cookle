extension RecipeFormModel {
    var hasUnsavedChanges: Bool {
        guard let initialChangeSnapshot else {
            return false
        }

        return changeSnapshot != initialChangeSnapshot
    }

    var formInput: RecipeFormInput {
        .init(
            name: name,
            photos: photos,
            servingSize: servingSize,
            cookingTime: cookingTime,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )
    }

    func captureInitialChangeSnapshotIfNeeded() {
        guard initialChangeSnapshot == nil else {
            return
        }

        acceptCurrentChanges()
    }

    func acceptCurrentChanges() {
        initialChangeSnapshot = changeSnapshot
    }
}

extension RecipeFormModel {
    /// The current input in the terms used to detect a meaningful change.
    var changeSnapshot: RecipeFormChangeSnapshot {
        .init(input: formInput)
    }
}
