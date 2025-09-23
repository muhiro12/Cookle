//
//  CookleMigrationPlan.swift
//  Cookle Playgrounds
//
//  Created by Hiromu Nakano on 2025/03/31.
//

import Foundation
import SwiftData

public enum CookleMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            CookleSchemaV1.self
        ]
    }

    public static var stages: [MigrationStage] {
        .empty
    }
}

private extension CookleMigrationPlan {
    enum CookleSchemaV1: VersionedSchema {
        static var models: [any PersistentModel.Type] {
            [
                Diary.self,
                DiaryObject.self,
                Photo.self,
                PhotoObject.self,
                Recipe.self,
                Category.self,
                Ingredient.self,
                IngredientObject.self
            ]
        }

        static var versionIdentifier: Schema.Version {
            .init(1, 0, 0)
        }
    }
}
