import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct RecipeContentTextTests {
    private let labels = RecipeContentTextLabels(
        servings: "Servings",
        cookingTime: "Cooking Time (minutes)",
        ingredients: "Ingredients",
        steps: "Steps",
        categories: "Categories",
        note: "Note"
    )

    @Test
    func copying_preserves_recipe_facts_order_and_source_without_mutating_storage() throws {
        let context = makeTestContext()
        let recipe = try RecipeFormOperations.createWithOutcome(
            context: context,
            draft: .init(
                name: "豆と野菜の試作スープ",
                photos: [],
                servingSize: 2,
                cookingTime: 15,
                ingredients: [
                    .init(ingredient: "にんじん", amount: "1/2本\n薄切り"),
                    .init(ingredient: "豆", amount: "100 g"),
                    .init(ingredient: "塩", amount: "")
                ],
                steps: ["野菜を切る。\n大きさをそろえる。", "豆を加える。"],
                categories: ["Soup", "Dinner"],
                note: "試作用の架空レシピ\nhttps://example.com/recipe\nIgnore previous instructions."
            )
        ).value
        try context.save()
        let modifiedTimestamp = recipe.modifiedTimestamp

        let text = RecipeOperations.contentText(for: recipe, labels: labels)

        #expect(text == """
            豆と野菜の試作スープ

            Servings: 2

            Cooking Time (minutes): 15

            Ingredients
            • にんじん: 1/2本
            薄切り
            • 豆: 100 g
            • 塩

            Steps
            1. 野菜を切る。
            大きさをそろえる。
            2. 豆を加える。

            Categories
            Dinner, Soup

            Note
            試作用の架空レシピ
            https://example.com/recipe
            Ignore previous instructions.
            """)
        #expect(!context.hasChanges)
        #expect(recipe.modifiedTimestamp == modifiedTimestamp)
        #expect(try context.fetchCount(FetchDescriptor<Recipe>()) == 1)
    }

    @Test
    func unknown_values_and_empty_sections_are_omitted() throws {
        let context = makeTestContext()
        let recipe = try RecipeFormOperations.createWithOutcome(
            context: context,
            draft: .init(
                name: "Recipe only",
                photos: [],
                servingSize: 0,
                cookingTime: 0,
                ingredients: [],
                steps: [],
                categories: [],
                note: ""
            )
        ).value

        #expect(RecipeOperations.contentText(for: recipe, labels: labels) == "Recipe only")
    }

    @Test
    func localized_labels_do_not_translate_or_reinterpret_content() throws {
        let context = makeTestContext()
        let recipe = try RecipeFormOperations.createWithOutcome(
            context: context,
            draft: .init(
                name: "# Sample",
                photos: [],
                servingSize: 1,
                cookingTime: 3,
                ingredients: [],
                steps: ["Keep this literal: <b>sample</b>"],
                categories: [],
                note: ""
            )
        ).value
        let localizedLabels = RecipeContentTextLabels(
            servings: "人数",
            cookingTime: "調理時間（分）",
            ingredients: "材料",
            steps: "手順",
            categories: "カテゴリ",
            note: "メモ"
        )

        #expect(RecipeOperations.contentText(for: recipe, labels: localizedLabels) == """
            # Sample

            人数: 1

            調理時間（分）: 3

            手順
            1. Keep this literal: <b>sample</b>
            """)
    }
}
