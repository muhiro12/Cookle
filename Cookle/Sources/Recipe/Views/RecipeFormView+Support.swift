import MHPlatform
import SwiftUI
import TipKit

extension RecipeFormView {
    @ViewBuilder var formSections: some View {
        @Bindable var bindableModel = formModel

        RecipeFormNameSection($bindableModel.name)
            .hidden(currentEditMode == .active)
        RecipeFormPhotosSection(
            $bindableModel.photos,
            addPhotoTip: currentRecipeFormTip(
                for: imagePlaygroundTip,
                isEligible: bindableModel.shouldShowImagePlaygroundTip
            )
        )
        if #available(iOS 26.0, *) {
            RecipeFormInferSection(
                name: $bindableModel.name,
                servingSize: $bindableModel.servingSize,
                cookingTime: $bindableModel.cookingTime,
                ingredients: $bindableModel.ingredients,
                steps: $bindableModel.steps,
                categories: $bindableModel.categories,
                note: $bindableModel.note,
                tip: currentRecipeFormTip(
                    for: inferRecipeFromTextTip,
                    isEligible: bindableModel.shouldShowInferRecipeFromTextTip
                )
            )
        }
        RecipeFormServingSizeSection($bindableModel.servingSize)
            .hidden(currentEditMode == .active)
        RecipeFormCookingTimeSection($bindableModel.cookingTime)
            .hidden(currentEditMode == .active)
        RecipeFormIngredientsSection($bindableModel.ingredients)
        RecipeFormStepsSection($bindableModel.steps)
        RecipeFormCategoriesSection($bindableModel.categories)
        RecipeFormNoteSection($bindableModel.note)
            .hidden(currentEditMode == .active)
        Section {
            Button {
                withAnimation {
                    currentEditMode = currentEditMode.isEditing ? .inactive : .active
                }
            } label: {
                currentEditMode == .inactive ? Text("Change Order or Delete Row") : Text("Done Edit")
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ToolbarContentBuilder var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                if formModel.name == "Enable Debug" {
                    formModel.name = .empty
                    isDebugConfirmationPresented = true
                    return
                }
                dismiss()
            } label: {
                Text("Cancel")
            }
        }
        switch currentEditMode {
        case .active:
            ToolbarItem {
                Button {
                    withAnimation {
                        currentEditMode = .inactive
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
        if formModel.restorePolicy.isRestoreAvailable {
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
                    let shouldDismiss = await formModel.save(
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
            .disabled((try? formModel.makeDraft()) == nil)
        }
    }

    var postCreatePhotoInputSources: [RecipePhotoInputSource] {
        RecipePhotoInputSource.allCases.filter(\.isAvailable)
    }

    var isErrorPresentedBinding: Binding<Bool> {
        .init(
            get: {
                formModel.errorMessage != nil
            },
            set: { isPresented in
                if isPresented == false {
                    formModel.errorMessage = nil
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

        if formModel.shouldShowInferRecipeFromTextTip {
            return inferRecipeFromTextTip.id == tip.id ? tip : nil
        }
        if formModel.shouldShowImagePlaygroundTip {
            return imagePlaygroundTip.id == tip.id ? tip : nil
        }

        return nil
    }

    func presentPostCreatePhotoInputSource(
        _ source: RecipePhotoInputSource
    ) {
        switch source {
        case .camera:
            isQuickAddCameraCoverPresented = true
        case .photoLibrary:
            isQuickAddPhotoLibraryCoverPresented = true
        case .imagePlayground:
            formModel.isImagePlaygroundPresented = true
        }
    }

    func appendPostCreatePhoto(
        _ data: Data,
        source: RecipePhotoInputSource
    ) {
        Task {
            guard let recipe = formModel.savedRecipe else {
                formModel.errorMessage = CookleActionError.recipeNotFound.localizedDescription
                return
            }

            do {
                try await recipeActionService.appendPhoto(
                    context: context,
                    recipe: recipe,
                    data: data,
                    source: source.persistedPhotoSource
                )
                dismiss()
            } catch {
                formModel.errorMessage = error.localizedDescription
            }
        }
    }

    func observeInferRecipeFromTextTipEligibility() async {
        await MainActor.run {
            formModel.updateInferRecipeFromTextTipEligibility(
                inferRecipeFromTextTip.shouldDisplay
            )
        }

        for await shouldDisplay in inferRecipeFromTextTip.shouldDisplayUpdates {
            await MainActor.run {
                formModel.updateInferRecipeFromTextTipEligibility(
                    shouldDisplay
                )
            }
        }
    }

    func observeImagePlaygroundTipEligibility() async {
        await MainActor.run {
            formModel.updateImagePlaygroundTipEligibility(
                imagePlaygroundTip.shouldDisplay
            )
        }

        for await shouldDisplay in imagePlaygroundTip.shouldDisplayUpdates {
            await MainActor.run {
                formModel.updateImagePlaygroundTipEligibility(
                    shouldDisplay
                )
            }
        }
    }

    func restoreDraft() {
        if formModel.restorePolicy.requiresOverwriteConfirmation {
            isRestoreDraftDialogPresented = true
            return
        }

        formModel.restoreSnapshot()
    }
}
