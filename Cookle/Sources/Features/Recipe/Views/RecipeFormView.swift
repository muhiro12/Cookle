//
//  RecipeFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import MHPlatform
import MHUI
import SwiftData
import SwiftUI
import TipKit

struct RecipeFormView: View {
    @State private var model: RecipeFormModel

    @Environment(\.dismiss)
    var dismiss

    @Environment(Recipe.self)
    var recipe: Recipe?
    @Environment(\.modelContext)
    var context
    @Environment(RecipeActionService.self)
    var recipeActionService
    @Environment(CookleAppLogging.self)
    var logging

    @AppStorage(\.isDebugOn)
    private var isDebugOn

    @State private var activeImportSource: RecipeImportSource?

    @State private var editMode = EditMode.inactive
    @State private var isDebugAlertPresented = false
    @State private var isRestoreDraftConfirmationPresented = false
    @State private var isDiscardChangesConfirmationPresented = false

    let type: RecipeFormType
    let inferRecipeFromTextTip = InferRecipeFromTextTip()
    let imagePlaygroundTip = ImagePlaygroundTip()

    var body: some View {
        @Bindable var model = model

        Form {
            formSections
        }
        .mhFormChrome()
        .disabled(model.isSaving)
        .environment(\.editMode, $editMode)
        .navigationTitle(editMode == .inactive ? Text("Recipe") : Text("Editing..."))
        .toolbar {
            toolbarItems
        }
        .sheet(item: $activeImportSource) { source in
            if #available(iOS 26.0, *) {
                InferRecipeFormNavigationView(
                    name: $model.name,
                    servingSize: $model.servingSize,
                    cookingTime: $model.cookingTime,
                    ingredients: $model.ingredients,
                    steps: $model.steps,
                    categories: $model.categories,
                    note: $model.note,
                    source: source
                )
                .interactiveDismissDisabled()
            }
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            Text("Debug"),
            isPresented: $isDebugAlertPresented
        ) {
            Button {
                model.name = ""
                isDebugOn = true
                dismiss()
            } label: {
                Text("OK")
            }
            Button(role: .cancel) {
                // Dismisses the confirmation dialog.
            } label: {
                Text("Cancel")
            }
        } message: {
            Text("Are you really going to use DebugMode?")
        }
        .confirmationDialog(
            Text("Restore Draft"),
            isPresented: $isRestoreDraftConfirmationPresented
        ) {
            Button("Restore Draft", role: .destructive) {
                model.restoreSnapshot()
            }
            Button("Cancel", role: .cancel) {
                // Dismisses the confirmation dialog.
            }
        } message: {
            Text("Replace the current form input with the saved draft?")
        }
        .alert(
            Text("Cannot Save Recipe"),
            isPresented: isErrorPresentedBinding
        ) {
            Button("OK", role: .cancel) {
                model.errorMessage = nil
            }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .task {
            model.applyRecipeIfNeeded(recipe)
            model.activateSnapshotPersistence(
                recipe: recipe
            )
        }
        .task {
            await observeInferRecipeFromTextTipEligibility()
        }
        .task {
            await observeImagePlaygroundTipEligibility()
        }
    }

    init(type: RecipeFormType, initialImportSource: RecipeImportSource? = nil) {
        _activeImportSource = State(initialValue: initialImportSource)
        self.type = type
        _model = State(
            initialValue: RecipeFormModel(
                type: type
            )
        )
    }
}

extension RecipeFormView {
    var importSourceSelection: Binding<RecipeImportSource?> {
        $activeImportSource
    }

    var formModel: RecipeFormModel {
        model
    }

    var currentEditMode: EditMode {
        get {
            editMode
        }
        nonmutating set {
            editMode = newValue
        }
    }

    var isDebugConfirmationPresented: Bool {
        get {
            isDebugAlertPresented
        }
        nonmutating set {
            isDebugAlertPresented = newValue
        }
    }

    var isRestoreDraftDialogPresented: Bool {
        get {
            isRestoreDraftConfirmationPresented
        }
        nonmutating set {
            isRestoreDraftConfirmationPresented = newValue
        }
    }

    var isDiscardChangesDialogPresented: Bool {
        get {
            isDiscardChangesConfirmationPresented
        }
        nonmutating set {
            isDiscardChangesConfirmationPresented = newValue
        }
    }
}

#Preview(traits: .modifier(CookleSampleData())) {
    RecipeFormNavigationView(type: .create)
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    RecipeFormNavigationView(type: .edit)
        .environment(recipes[0])
}
