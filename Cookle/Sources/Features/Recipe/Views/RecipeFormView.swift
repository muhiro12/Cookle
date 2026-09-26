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
    static let ingredientsSectionID = "recipeFormIngredientsSection"

    private let model: RecipeFormModel

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.modelContext)
    var context
    @Environment(RecipeActionService.self)
    var recipeActionService
    @Environment(CookleAppLogging.self)
    var logging
    @Environment(MainNavigationModel.self)
    var navigationModel

    @AppStorage(\.isDebugOn)
    private var isDebugOn

    @State private var editMode = EditMode.inactive
    @State private var isDebugAlertPresented = false
    @State private var isRestoreDraftConfirmationPresented = false
    @State private var isDiscardChangesConfirmationPresented = false
    @State private var isUndoImportConfirmationPresented = false

    let type: RecipeFormType
    let inferRecipeFromTextTip = InferRecipeFromTextTip()
    let imagePlaygroundTip = ImagePlaygroundTip()

    var body: some View {
        @Bindable var model = model

        ScrollViewReader { scrollProxy in
            Form {
                formSections
            }
            .task(id: model.ingredients.count) {
                await scrollToCaptureSectionIfNeeded(
                    using: scrollProxy
                )
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .mhFormChrome(.content)
        .disabled(model.isSaving)
        .environment(\.editMode, $editMode)
        .navigationTitle(editMode == .inactive ? Text("Recipe") : Text("Editing..."))
        .toolbar {
            toolbarItems
        }
        .sheet(item: $model.importSource) { source in
            if #available(iOS 26.0, *) {
                InferRecipeFormNavigationView(
                    model: model,
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
        .confirmationDialog(
            Text("Undo Import?"),
            isPresented: $isUndoImportConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Undo Import", role: .destructive) {
                model.undoInference()
            }
            Button("Cancel", role: .cancel) {
                // Keeps the imported recipe and the later changes.
            }
        } message: {
            Text(
                """
                This restores the recipe input from before the import and also discards \
                the changes you made after importing.
                """
            )
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
            model.applyRecipeIfNeeded()
            model.activateSnapshotPersistence()
        }
        .task {
            await observeInferRecipeFromTextTipEligibility()
        }
        .task {
            await observeImagePlaygroundTipEligibility()
        }
    }

    init(model: RecipeFormModel) {
        self.model = model
        type = model.type
    }
}

extension RecipeFormView {
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

    var isUndoImportDialogPresented: Bool {
        get {
            isUndoImportConfirmationPresented
        }
        nonmutating set {
            isUndoImportConfirmationPresented = newValue
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
    @Previewable @State var model = RecipeFormModel(type: .create)
    RecipeFormNavigationView(model: model)
}

#Preview(traits: .modifier(CookleSampleData())) {
    @Previewable @Query var recipes: [Recipe]
    RecipeFormNavigationView(
        model: .init(
            type: .edit,
            recipe: recipes[0]
        )
    )
}
