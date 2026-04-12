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
    private var dismiss

    @Environment(Recipe.self)
    private var recipe: Recipe?
    @Environment(\.modelContext)
    private var context
    @Environment(RecipeActionService.self)
    private var recipeActionService
    @Environment(CookleAppLogging.self)
    private var logging

    @AppStorage(BoolPreferenceKey.isDebugOn)
    private var isDebugOn

    @State private var editMode = EditMode.inactive
    @State private var isDebugAlertPresented = false
    @State private var isRestoreDraftConfirmationPresented = false

    private let type: RecipeFormType
    private let inferRecipeFromTextTip = InferRecipeFromTextTip()
    private let imagePlaygroundTip = ImagePlaygroundTip()

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
            Button("Use Image Playground") {
                model.isImagePlaygroundPresented = true
            }
            Button("Later", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("No image yet. Try Image Playground?")
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

    @ViewBuilder var formSections: some View {
        @Bindable var model = model

        RecipeFormNameSection($model.name)
            .hidden(editMode == .active)
        RecipeFormPhotosSection(
            $model.photos,
            addPhotoTip: currentRecipeFormTip(
                for: imagePlaygroundTip,
                isEligible: model.shouldShowImagePlaygroundTip
            )
        )
        if #available(iOS 26.0, *) {
            RecipeFormInferSection(
                name: $model.name,
                servingSize: $model.servingSize,
                cookingTime: $model.cookingTime,
                ingredients: $model.ingredients,
                steps: $model.steps,
                categories: $model.categories,
                note: $model.note,
                tip: currentRecipeFormTip(
                    for: inferRecipeFromTextTip,
                    isEligible: model.shouldShowInferRecipeFromTextTip
                )
            )
        }
        RecipeFormServingSizeSection($model.servingSize)
            .hidden(editMode == .active)
        RecipeFormCookingTimeSection($model.cookingTime)
            .hidden(editMode == .active)
        RecipeFormIngredientsSection($model.ingredients)
        RecipeFormStepsSection($model.steps)
        RecipeFormCategoriesSection($model.categories)
        RecipeFormNoteSection($model.note)
            .hidden(editMode == .active)
        Section {
            Button {
                withAnimation {
                    editMode = editMode.isEditing ? .inactive : .active
                }
            } label: {
                editMode == .inactive ? Text("Change Order or Delete Row") : Text("Done Edit")
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                if model.name == "Enable Debug" {
                    model.name = .empty
                    isDebugAlertPresented = true
                    return
                }
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
        switch editMode {
        case .active:
            ToolbarItem {
                Button {
                    withAnimation {
                        editMode = .inactive
                    }
                } label: {
                    Text("Done")
                }
            }
        default:
            restoreToolbarItem
            confirmationToolbarItem
        }
    }

    @ToolbarContentBuilder var restoreToolbarItem: some ToolbarContent {
        if model.restorePolicy.isRestoreAvailable {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Restore Draft") {
                    restoreDraft()
                }
            }
        }
    }

    @ToolbarContentBuilder var confirmationToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                Task {
                    let shouldDismiss = await model.save(
                        context: context,
                        recipe: recipe,
                        recipeActionService: recipeActionService,
                        draftLogger: logging.logger(
                            category: "RecipeDraft",
                            source: #fileID
                        )
                    )
                    if shouldDismiss {
                        dismiss()
                    }
                }
            } label: {
                switch type {
                case .create,
                     .duplicate:
                    Text("Create")
                case .edit:
                    Text("Update")
                }
            }
            .disabled((try? model.makeDraft()) == nil)
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

private extension RecipeFormView {
    var isErrorPresentedBinding: Binding<Bool> {
        .init(
            get: {
                model.errorMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    model.errorMessage = nil
                }
            }
        )
    }

    func currentRecipeFormTip<T: Tip>(
        for tip: T,
        isEligible: Bool
    ) -> (any Tip)? {
        guard isEligible else {
            return nil
        }

        if model.shouldShowInferRecipeFromTextTip {
            return inferRecipeFromTextTip.id == tip.id ? tip : nil
        }
        if model.shouldShowImagePlaygroundTip {
            return imagePlaygroundTip.id == tip.id ? tip : nil
        }

        return nil
    }

    func observeInferRecipeFromTextTipEligibility() async {
        await MainActor.run {
            model.updateInferRecipeFromTextTipEligibility(
                inferRecipeFromTextTip.shouldDisplay
            )
        }

        for await shouldDisplay in inferRecipeFromTextTip.shouldDisplayUpdates {
            await MainActor.run {
                model.updateInferRecipeFromTextTipEligibility(
                    shouldDisplay
                )
            }
        }
    }

    func observeImagePlaygroundTipEligibility() async {
        await MainActor.run {
            model.updateImagePlaygroundTipEligibility(
                imagePlaygroundTip.shouldDisplay
            )
        }

        for await shouldDisplay in imagePlaygroundTip.shouldDisplayUpdates {
            await MainActor.run {
                model.updateImagePlaygroundTipEligibility(
                    shouldDisplay
                )
            }
        }
    }

    func restoreDraft() {
        if model.restorePolicy.requiresOverwriteConfirmation {
            isRestoreDraftConfirmationPresented = true
            return
        }

        model.restoreSnapshot()
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
