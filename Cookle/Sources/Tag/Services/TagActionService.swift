import Observation
import SwiftData

@MainActor
@Observable
final class TagActionService {
    func rename(
        context: ModelContext,
        ingredient: Ingredient,
        value: String
    ) throws {
        try TagService.rename(
            context: context,
            ingredient: ingredient,
            value: value
        )
    }

    func rename(
        context: ModelContext,
        category: Category,
        value: String
    ) throws {
        try TagService.rename(
            context: context,
            category: category,
            value: value
        )
    }

    func delete(
        context: ModelContext,
        ingredient: Ingredient
    ) throws {
        try TagService.delete(
            context: context,
            ingredient: ingredient
        )
    }

    func delete(
        context: ModelContext,
        category: Category
    ) throws {
        try TagService.delete(
            context: context,
            category: category
        )
    }

    func rename<T: Tag>(
        context: ModelContext,
        tag: T,
        value: String
    ) async throws {
        if let ingredient = tag as? Ingredient {
            try await rename(
                context: context,
                ingredient: ingredient,
                value: value
            )
            return
        }

        if let category = tag as? Category {
            try await rename(
                context: context,
                category: category,
                value: value
            )
            return
        }

        preconditionFailure("Unsupported tag type: \(T.self)")
    }

    func delete<T: Tag>(
        context: ModelContext,
        tag: T
    ) async throws {
        if let ingredient = tag as? Ingredient {
            try await delete(
                context: context,
                ingredient: ingredient
            )
            return
        }

        if let category = tag as? Category {
            try await delete(
                context: context,
                category: category
            )
            return
        }

        preconditionFailure("Unsupported tag type: \(T.self)")
    }
}
