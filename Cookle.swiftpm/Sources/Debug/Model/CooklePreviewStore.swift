//
//  CooklePreviewStore.swift
//
//
//  Created by Hiromu Nakano on 2024/06/05.
//

import SwiftData
import SwiftUI

@Observable
final class CooklePreviewStore {
    private(set) var diaries = [Diary]()
    private(set) var diaryObjects = [DiaryObject]()
    private(set) var recipes = [Recipe]()
    private(set) var ingredients = [Ingredient]()
    private(set) var ingredientObjects = [IngredientObject]()
    private(set) var categories = [Category]()
    private(set) var photos = [Photo]()
    private(set) var photoObjects = [PhotoObject]()

    private var isReady: Bool {
        !diaries.isEmpty
            && !diaryObjects.isEmpty
            && !recipes.isEmpty
            && !ingredients.isEmpty
            && !ingredientObjects.isEmpty
            && !categories.isEmpty
            && !photos.isEmpty
            && !photoObjects.isEmpty
    }

    @MainActor
    func prepare(_ context: ModelContext) async {
        (0..<20).forEach { _ in
            _ = createPreviewDiary(context)
        }
        while !isReady {
            try! await Task.sleep(for: .seconds(0.2))
            diaries = try! context.fetch(.init())
            diaryObjects = try! context.fetch(.init())
            recipes = try! context.fetch(.init())
            ingredients = try! context.fetch(.init())
            ingredientObjects = try! context.fetch(.init())
            categories = try! context.fetch(.init())
            photos = try! context.fetch(.init())
            photoObjects = try! context.fetch(.init())
        }
    }

    func createPreviewDiary(_ context: ModelContext) -> Diary {
        .create(
            context: context,
            date: .now,
            objects: [
                .create(
                    context: context,
                    recipe: cookPancakes(context),
                    type: .breakfast,
                    order: 1
                ),
                .create(
                    context: context,
                    recipe: cookChickenStirFry(context),
                    type: .lunch,
                    order: 1
                ),
                .create(
                    context: context,
                    recipe: cookVegetableSoup(context),
                    type: .lunch,
                    order: 2
                ),
                .create(
                    context: context,
                    recipe: cookSpaghettiCarbonara(context),
                    type: .dinner,
                    order: 1
                ),
                .create(
                    context: context,
                    recipe: cookBeefStew(context),
                    type: .dinner,
                    order: 2
                )
            ],
            note: """
                  Today's menu:
                  - Breakfast: Delicious pancakes served with syrup, butter, and fresh fruits.
                  - Lunch: Chicken stir fry with bell peppers and broccoli, accompanied by a hearty vegetable soup.
                  - Dinner: Classic spaghetti carbonara and warm beef stew for a comforting end to the day.

                  Tips:
                  - Try adding blueberries or bananas to the pancakes for extra flavor.
                  - The vegetable soup can be stored for up to 3 days, making it perfect for leftovers.
                  - The beef stew tastes even better the next day, so make extra for an easy meal tomorrow.
                  """
        )
    }

    private func cookSpaghettiCarbonara(_ context: ModelContext) -> Recipe {
        .create(
            context: context,
            name: "Spaghetti Carbonara",
            photos: photoObjects(context: context),
            servingSize: 2,
            cookingTime: 30,
            ingredients: [
                .create(context: context, ingredient: "Spaghetti", amount: "200g", order: 1),
                .create(context: context, ingredient: "Eggs", amount: "2", order: 2),
                .create(context: context, ingredient: "Parmesan cheese", amount: "50g", order: 3),
                .create(context: context, ingredient: "Pancetta", amount: "100g", order: 4),
                .create(context: context, ingredient: "Black pepper", amount: "to taste", order: 5),
                .create(context: context, ingredient: "Salt", amount: "to taste", order: 6)
            ],
            steps: [
                "Boil water in a large pot and add salt.",
                "Cook the spaghetti until al dente.",
                "In a separate pan, cook the pancetta until crispy.",
                "Beat the eggs in a bowl and mix with grated Parmesan cheese.",
                "Drain the spaghetti and mix with pancetta and the egg mixture.",
                "Season with black pepper and serve immediately."
            ],
            categories: [
                .create(context: context, value: "Italian")
            ],
            note: "Use freshly grated Parmesan for the best flavor."
        )
    }

    private func cookBeefStew(_ context: ModelContext) -> Recipe {
        .create(
            context: context,
            name: "Beef Stew",
            photos: photoObjects(context: context),
            servingSize: 6,
            cookingTime: 120,
            ingredients: [
                .create(context: context, ingredient: "Beef chuck", amount: "1 kg", order: 1),
                .create(context: context, ingredient: "Carrots", amount: "3", order: 2),
                .create(context: context, ingredient: "Potatoes", amount: "4", order: 3),
                .create(context: context, ingredient: "Onions", amount: "2", order: 4),
                .create(context: context, ingredient: "Beef broth", amount: "4 cups", order: 5),
                .create(context: context, ingredient: "Tomato paste", amount: "2 tbsp", order: 6),
                .create(context: context, ingredient: "Flour", amount: "1/4 cup", order: 7),
                .create(context: context, ingredient: "Salt", amount: "to taste", order: 8),
                .create(context: context, ingredient: "Black pepper", amount: "to taste", order: 9),
                .create(context: context, ingredient: "Olive oil", amount: "2 tbsp", order: 10)
            ],
            steps: [
                "Cut the beef into large chunks and season with salt and pepper.",
                "Heat the oil in a large pot over medium-high heat.",
                "Brown the beef on all sides, then remove from the pot.",
                "Add the chopped onions, carrots, and potatoes to the pot and cook for 5 minutes.",
                "Stir in the flour and tomato paste, and cook for another minute.",
                "Return the beef to the pot and add the beef broth.",
                "Bring to a boil, then reduce the heat and simmer for 2 hours, until the beef is tender.",
                "Season with salt and pepper to taste, and serve hot."
            ],
            categories: [
                .create(context: context, value: "Comfort Food")
            ],
            note: "This stew is even better the next day."
        )
    }

    private func cookChickenStirFry(_ context: ModelContext) -> Recipe {
        .create(
            context: context,
            name: "Chicken Stir Fry",
            photos: photoObjects(context: context),
            servingSize: 4,
            cookingTime: 20,
            ingredients: [
                .create(context: context, ingredient: "Chicken breast", amount: "500g", order: 1),
                .create(context: context, ingredient: "Bell peppers", amount: "2", order: 2),
                .create(context: context, ingredient: "Broccoli", amount: "1 head", order: 3),
                .create(context: context, ingredient: "Soy sauce", amount: "3 tbsp", order: 4),
                .create(context: context, ingredient: "Garlic", amount: "2 cloves", order: 5),
                .create(context: context, ingredient: "Ginger", amount: "1 inch", order: 6),
                .create(context: context, ingredient: "Vegetable oil", amount: "2 tbsp", order: 7),
                .create(context: context, ingredient: "Cornstarch", amount: "1 tbsp", order: 8),
                .create(context: context, ingredient: "Water", amount: "1/2 cup", order: 9)
            ],
            steps: [
                "Cut the chicken into bite-sized pieces.",
                "Chop the bell peppers and broccoli into small pieces.",
                "Heat the oil in a large skillet over medium-high heat.",
                "Add the chicken and cook until browned.",
                "Add the garlic and ginger, and cook for another minute.",
                "Add the bell peppers and broccoli, and cook until tender.",
                "Mix the soy sauce, cornstarch, and water in a small bowl.",
                "Pour the sauce over the chicken and vegetables, and cook until thickened.",
                "Serve hot with rice."
            ],
            categories: [
                .create(context: context, value: "Asian")
            ],
            note: "You can use any vegetables you like for this stir fry."
        )
    }

    private func cookVegetableSoup(_ context: ModelContext) -> Recipe {
        .create(
            context: context,
            name: "Vegetable Soup",
            photos: photoObjects(context: context),
            servingSize: 4,
            cookingTime: 40,
            ingredients: [
                .create(context: context, ingredient: "Carrots", amount: "3", order: 1),
                .create(context: context, ingredient: "Potatoes", amount: "2", order: 2),
                .create(context: context, ingredient: "Celery", amount: "2 stalks", order: 3),
                .create(context: context, ingredient: "Onion", amount: "1", order: 4),
                .create(context: context, ingredient: "Garlic", amount: "2 cloves", order: 5),
                .create(context: context, ingredient: "Vegetable broth", amount: "6 cups", order: 6),
                .create(context: context, ingredient: "Tomatoes", amount: "2", order: 7),
                .create(context: context, ingredient: "Salt", amount: "to taste", order: 8),
                .create(context: context, ingredient: "Black pepper", amount: "to taste", order: 9),
                .create(context: context, ingredient: "Olive oil", amount: "2 tbsp", order: 10)
            ],
            steps: [
                "Chop the carrots, potatoes, celery, onion, and tomatoes.",
                "Heat the oil in a large pot over medium heat.",
                "Add the chopped onions and garlic, and sauté until golden brown.",
                "Add the carrots, potatoes, and celery, and cook for another 5 minutes.",
                "Pour in the vegetable broth and bring to a boil.",
                "Reduce the heat and simmer for 20 minutes, until the vegetables are tender.",
                "Season with salt and pepper to taste.",
                "Serve hot with a sprinkle of fresh herbs."
            ],
            categories: [
                .create(context: context, value: "Healthy")
            ],
            note: "You can add any vegetables you have on hand."
        )
    }

    private func cookPancakes(_ context: ModelContext) -> Recipe {
        .create(
            context: context,
            name: "Pancakes",
            photos: photoObjects(context: context),
            servingSize: 4,
            cookingTime: 20,
            ingredients: [
                .create(context: context, ingredient: "All-purpose flour", amount: "1 cup", order: 1),
                .create(context: context, ingredient: "Milk", amount: "1 cup", order: 2),
                .create(context: context, ingredient: "Egg", amount: "1", order: 3),
                .create(context: context, ingredient: "Baking powder", amount: "2 tsp", order: 4),
                .create(context: context, ingredient: "Salt", amount: "1/4 tsp", order: 5),
                .create(context: context, ingredient: "Sugar", amount: "1 tbsp", order: 6),
                .create(context: context, ingredient: "Butter", amount: "2 tbsp", order: 7)
            ],
            steps: [
                "In a large bowl, mix together the flour, baking powder, salt, and sugar.",
                "Make a well in the center and pour in the milk, egg, and melted butter.",
                "Mix until smooth.",
                "Heat a lightly oiled griddle or frying pan over medium-high heat.",
                "Pour or scoop the batter onto the griddle, using approximately 1/4 cup for each pancake.",
                "Brown on both sides and serve hot."
            ],
            categories: [
                .create(context: context, value: "Breakfast")
            ],
            note: "Serve with syrup, butter, and fresh fruits."
        )
    }

    private func photoObjects(context: ModelContext) -> [PhotoObject] {
        [
            .create(context: context, photo: UIImage(systemName: "fork.knife")!.jpegData(compressionQuality: 1.0)!, order: 1),
            .create(context: context, photo: UIImage(systemName: "cup.and.saucer")!.jpegData(compressionQuality: 1.0)!, order: 2),
            .create(context: context, photo: UIImage(systemName: "takeoutbag.and.cup.and.straw")!.jpegData(compressionQuality: 1.0)!, order: 3),
            .create(context: context, photo: UIImage(systemName: "leaf")!.jpegData(compressionQuality: 1.0)!, order: 4)
        ]
    }
}
