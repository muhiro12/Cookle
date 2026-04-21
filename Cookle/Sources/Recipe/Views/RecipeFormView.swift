//
//  RecipeFormView.swift
//  Cookle
//
//  Created by Hiromu Nakano on 2024/04/11.
//

import MHPlatform
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

    @State private var editMode = EditMode.inactive
    @State private var isDebugAlertPresented = false
    @State private var isRestoreDraftConfirmationPresented = false
    @State private var isQuickAddCameraPresented = false
    @State private var isQuickAddPhotoLibraryPresented = false

    let type: RecipeFormType
    let inferRecipeFromTextTip = InferRecipeFromTextTip()
    let imagePlaygroundTip = ImagePlaygroundTip()

    var body: some View {
        @Bindable var model = model

        Form {
            formSections
        }
        .environment(\.editMode, $editMode)
        .navigationTitle(editMode == .inactive ? Text("Recipe") : Text("Editing..."))
        .toolbar {
            toolbarItems
        }
        .interactiveDismissDisabled()
        .confirmationDialog(
            Text("Debug"),
            isPresented: $isDebugAlertPresented
        ) {
            Button {
                model.name = .empty
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
            Text("Add a photo?"),
            isPresented: $model.isPhotoConfirmationPresented
        ) {
            ForEach(postCreatePhotoInputSources) { source in
                Button {
                    presentPostCreatePhotoInputSource(source)
                } label: {
                    source.titleText
                }
            }
            Button("Later", role: .cancel) {
                dismiss()
            }
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
        .fullScreenCover(isPresented: $isQuickAddCameraPresented) {
            CameraPicker { data in
                appendPostCreatePhoto(
                    data,
                    source: .camera
                )
            } cancellationHandler: {
                dismiss()
            }
        }
        .fullScreenCover(isPresented: $isQuickAddPhotoLibraryPresented) {
            SinglePhotoLibraryPicker { data in
                appendPostCreatePhoto(
                    data,
                    source: .photoLibrary
                )
            } cancellationHandler: {
                dismiss()
            }
        }
        .cookleImagePlayground(
            isPresented: $model.isImagePlaygroundPresented,
            recipe: model.savedRecipe
        ) { data in
            Task {
                guard let recipe = model.savedRecipe else {
                    model.errorMessage = CookleActionError.recipeNotFound.localizedDescription
                    return
                }

                do {
                    _ = try await recipeActionService.replaceGeneratedPhoto(
                        context: context,
                        recipe: recipe,
                        data: data
                    )
                    dismiss()
                } catch {
                    model.errorMessage = error.localizedDescription
                }
            }
        } onCancellation: {
            dismiss()
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

    init(type: RecipeFormType) {
        self.type = type
        _model = State(
            initialValue: RecipeFormModel(
                type: type
            )
        )
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

    var isQuickAddCameraCoverPresented: Bool {
        get {
            isQuickAddCameraPresented
        }
        nonmutating set {
            isQuickAddCameraPresented = newValue
        }
    }

    var isQuickAddPhotoLibraryCoverPresented: Bool {
        get {
            isQuickAddPhotoLibraryPresented
        }
        nonmutating set {
            isQuickAddPhotoLibraryPresented = newValue
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
