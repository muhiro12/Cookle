import Foundation
import SwiftData

/// Explicit inspector mutations that preserve Cookle's current relationship rules.
/// Product surfaces use their domain Operations and deletion reviews instead.
@preconcurrency
@MainActor
public enum DiagnosticOperations {
    /// Deletes one inspected record, rebuilding its owner's derived relations when needed.
    /// The caller owns saving, rollback, and follow-up effects. Missing targets,
    /// unsupported models, and ingredients still used by recipes leave the graph untouched.
    public static func deleteWithOutcome<Model: PersistentModel>(
        context: ModelContext,
        model: Model
    ) throws -> MutationOutcome<Void> {
        let currentModel = try resolvedModel(model, context: context)
        switch currentModel {
        case let recipe as Recipe:
            return RecipeOperations.deleteWithOutcome(context: context, recipe: recipe)
        case let diary as Diary:
            return DiaryOperations.deleteWithOutcome(context: context, diary: diary)
        case let photo as Photo:
            return PhotoOperations.deleteWithOutcome(context: context, photo: photo)
        case let category as Category:
            return TagOperations.deleteWithOutcome(context: context, category: category)
        case let ingredient as Ingredient:
            return try deleteIngredient(context: context, ingredient: ingredient)
        case let object as PhotoObject:
            return deletePhotoObject(context: context, object: object)
        case let object as IngredientObject:
            return deleteIngredientObject(context: context, object: object)
        case let object as DiaryObject:
            return deleteDiaryObject(context: context, object: object)
        default:
            throw DeletionError.unsupportedModel
        }
    }
}

private extension DiagnosticOperations {
    enum DeletionError: LocalizedError {
        case unsupportedModel

        var errorDescription: String? {
            "This model does not support diagnostic deletion."
        }
    }

    static func deleteIngredient(context: ModelContext, ingredient: Ingredient) throws -> MutationOutcome<Void> {
        // An attached amount row also establishes use when a flattened relation
        // is incomplete during import.
        guard (ingredient.objects ?? []).allSatisfy({ object in
            object.recipe == nil
        }) else {
            throw TagOperationsError.ingredientInUse(ingredient.value)
        }
        return try TagOperations.deleteWithOutcome(context: context, ingredient: ingredient)
    }

    static func deletePhotoObject(context: ModelContext, object: PhotoObject) -> MutationOutcome<Void> {
        if let recipe = object.recipe {
            return RecipeOperations.removePhotoWithOutcome(context: context, recipe: recipe, photoObject: object)
        }
        context.delete(object)
        return .init(value: (), effects: [.recipeDataChanged, .notificationPlanChanged])
    }

    static func deleteIngredientObject(context: ModelContext, object: IngredientObject) -> MutationOutcome<Void> {
        if let recipe = object.recipe {
            var content = recipe.content
            content.ingredients = (recipe.ingredientObjects ?? []).filter { row in
                row.persistentModelID != object.persistentModelID
            }
            recipe.update(content: content)
        }
        context.delete(object)
        return .init(value: (), effects: [.recipeDataChanged, .notificationPlanChanged])
    }

    static func deleteDiaryObject(context: ModelContext, object: DiaryObject) -> MutationOutcome<Void> {
        if let diary = object.diary {
            diary.update(content: .init(
                date: diary.date,
                objects: (diary.objects ?? []).filter { row in
                    row.persistentModelID != object.persistentModelID
                },
                note: diary.note
            ))
        }
        context.delete(object)
        return .init(value: (), effects: [.recipeDataChanged, .diaryDataChanged, .notificationPlanChanged])
    }

    static func resolvedModel<Model: PersistentModel>(
        _ model: Model,
        context: ModelContext
    ) throws -> Model {
        guard model.isDeleted == false else {
            throw ReviewedMutationError.targetMissing
        }
        let identifier = model.persistentModelID
        var descriptor = FetchDescriptor<Model>()
        descriptor.includePendingChanges = false
        // The inspector already queries the complete selected entity. A concrete
        // fetch avoids generic predicate translation and rejects stale selections.
        guard let currentModel = try context.fetch(descriptor).first(where: { candidate in
            candidate.persistentModelID == identifier
        }) else {
            throw ReviewedMutationError.targetMissing
        }
        return currentModel
    }
}
