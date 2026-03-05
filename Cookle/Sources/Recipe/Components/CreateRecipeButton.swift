//
//  CreateRecipeButton.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 9/21/24.
//

import SwiftUI

struct CreateRecipeButton: View {
    @Environment(\.modelContext)
    private var context
    @Environment(\.dismiss)
    private var dismiss
    @Environment(RecipeActionService.self)
    private var recipeActionService

    @State private var recipe: Recipe?
    @State private var isConfirmationDialogPresented = false
    @State private var isImagePlaygroundPresented = false

    private let name: String
    private let photos: [PhotoData]
    private let servingSize: String
    private let cookingTime: String
    private let ingredients: [RecipeFormIngredient]
    private let steps: [String]
    private let categories: [String]
    private let note: String

    private let useShortTitle: Bool

    var body: some View {
        Button {
            Task {
                do {
                    let draft = try RecipeFormService.makeDraft(
                        name: name,
                        photos: photos,
                        servingSize: servingSize,
                        cookingTime: cookingTime,
                        ingredients: ingredients,
                        steps: steps,
                        categories: categories,
                        note: note
                    )
                    let shouldRequestReview = photos.isNotEmpty
                        || CookleImagePlayground.isSupported == false
                    let outcome = await recipeActionService.create(
                        context: context,
                        draft: draft,
                        requestReview: shouldRequestReview
                    )
                    recipe = outcome.value
                    if recipe?.photos?.isEmpty == true,
                       CookleImagePlayground.isSupported {
                        isConfirmationDialogPresented = true
                    } else {
                        dismiss()
                    }
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        } label: {
            Label {
                if useShortTitle {
                    Text("Create")
                } else {
                    Text("Create \(name)")
                }
            } icon: {
                Image(systemName: "book.pages")
                    .accessibilityHidden(true)
            }
        }
        .disabled(
            (try? RecipeFormService.makeDraft(
                name: name,
                photos: photos,
                servingSize: servingSize,
                cookingTime: cookingTime,
                ingredients: ingredients,
                steps: steps,
                categories: categories,
                note: note
            )) == nil
        )
        .confirmationDialog(
            Text("Add a photo?"),
            isPresented: $isConfirmationDialogPresented
        ) {
            Button("Use Image Playground") {
                isImagePlaygroundPresented = true
            }
            Button("Later", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("No image yet. Try Image Playground?")
        }
        .cookleImagePlayground(
            isPresented: $isImagePlaygroundPresented,
            recipe: recipe
        ) { data in
            Task {
                if let recipe {
                    _ = await recipeActionService.replaceGeneratedPhoto(
                        context: context,
                        recipe: recipe,
                        data: data
                    )
                }
                dismiss()
            }
        } onCancellation: {
            dismiss()
        }
    }

    init(name: String,
         photos: [PhotoData],
         servingSize: String,
         cookingTime: String,
         ingredients: [RecipeFormIngredient],
         steps: [String],
         categories: [String],
         note: String,
         useShortTitle: Bool = false) {
        self.name = name
        self.photos = photos
        self.servingSize = servingSize
        self.cookingTime = cookingTime
        self.ingredients = ingredients
        self.steps = steps
        self.categories = categories
        self.note = note
        self.useShortTitle = useShortTitle
    }
}

#Preview {
    CreateRecipeButton(
        name: .empty,
        photos: .empty,
        servingSize: .empty,
        cookingTime: .empty,
        ingredients: .empty,
        steps: .empty,
        categories: .empty,
        note: .empty
    )
}
