import Foundation
import SwiftData

extension CooklePreviewStore {
    struct PreviewIngredient {
        let name: String
        let amount: String
    }

    private enum RecipeConstants {
        static let firstOrder = 1
        static let firstServingSize = 2
        static let secondServingSize = 4
        static let thirdServingSize = 6
        static let shortCookingTime = 20
        static let mediumCookingTime = 30
        static let longCookingTime = 40
        static let stewCookingTime = 120
    }

    func cookSpaghettiCarbonara(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Spaghetti Carbonara",
            photos: createPhotoObjects(
                context,
                assets: [.spaghettiCarbonara1, .spaghettiCarbonara2],
                remotePhotoDataMap: remotePhotoDataMap
            ),
            servingSize: RecipeConstants.firstServingSize,
            cookingTime: RecipeConstants.mediumCookingTime,
            ingredients: ingredientObjects(
                context,
                items: [
                    .init(name: "Spaghetti", amount: "200g"),
                    .init(name: "Eggs", amount: "2"),
                    .init(name: "Parmesan cheese", amount: "50g"),
                    .init(name: "Pancetta", amount: "100g"),
                    .init(name: "Black pepper", amount: "to taste"),
                    .init(name: "Salt", amount: "to taste")
                ]
            ),
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

    func cookBeefStew(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Beef Stew",
            photos: createPhotoObjects(
                context,
                assets: [.beefStew1, .beefStew2],
                remotePhotoDataMap: remotePhotoDataMap
            ),
            servingSize: RecipeConstants.thirdServingSize,
            cookingTime: RecipeConstants.stewCookingTime,
            ingredients: ingredientObjects(
                context,
                items: [
                    .init(name: "Beef chuck", amount: "1 kg"),
                    .init(name: "Carrots", amount: "3"),
                    .init(name: "Potatoes", amount: "4"),
                    .init(name: "Onions", amount: "2"),
                    .init(name: "Beef broth", amount: "4 cups"),
                    .init(name: "Tomato paste", amount: "2 tbsp"),
                    .init(name: "Flour", amount: "1/4 cup"),
                    .init(name: "Salt", amount: "to taste"),
                    .init(name: "Black pepper", amount: "to taste"),
                    .init(name: "Olive oil", amount: "2 tbsp")
                ]
            ),
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

    func cookChickenStirFry(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Chicken Stir Fry",
            photos: createPhotoObjects(
                context,
                assets: [.chickenStirFry1, .chickenStirFry2],
                remotePhotoDataMap: remotePhotoDataMap
            ),
            servingSize: RecipeConstants.secondServingSize,
            cookingTime: RecipeConstants.shortCookingTime,
            ingredients: ingredientObjects(
                context,
                items: [
                    .init(name: "Chicken breast", amount: "500g"),
                    .init(name: "Bell peppers", amount: "2"),
                    .init(name: "Broccoli", amount: "1 head"),
                    .init(name: "Soy sauce", amount: "3 tbsp"),
                    .init(name: "Garlic", amount: "2 cloves"),
                    .init(name: "Ginger", amount: "1 inch"),
                    .init(name: "Vegetable oil", amount: "2 tbsp"),
                    .init(name: "Cornstarch", amount: "1 tbsp"),
                    .init(name: "Water", amount: "1/2 cup")
                ]
            ),
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

    func cookVegetableSoup(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Vegetable Soup",
            photos: createPhotoObjects(
                context,
                assets: [.vegetableSoup1, .vegetableSoup2],
                remotePhotoDataMap: remotePhotoDataMap
            ),
            servingSize: RecipeConstants.secondServingSize,
            cookingTime: RecipeConstants.longCookingTime,
            ingredients: ingredientObjects(
                context,
                items: [
                    .init(name: "Carrots", amount: "3"),
                    .init(name: "Potatoes", amount: "2"),
                    .init(name: "Celery", amount: "2 stalks"),
                    .init(name: "Onion", amount: "1"),
                    .init(name: "Garlic", amount: "2 cloves"),
                    .init(name: "Vegetable broth", amount: "6 cups"),
                    .init(name: "Tomatoes", amount: "2"),
                    .init(name: "Salt", amount: "to taste"),
                    .init(name: "Black pepper", amount: "to taste"),
                    .init(name: "Olive oil", amount: "2 tbsp")
                ]
            ),
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

    func cookPancakes(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Pancakes",
            photos: createPhotoObjects(
                context,
                assets: [.pancakes1, .pancakes2],
                remotePhotoDataMap: remotePhotoDataMap
            ),
            servingSize: RecipeConstants.secondServingSize,
            cookingTime: RecipeConstants.shortCookingTime,
            ingredients: ingredientObjects(
                context,
                items: [
                    .init(name: "All-purpose flour", amount: "1 cup"),
                    .init(name: "Milk", amount: "1 cup"),
                    .init(name: "Egg", amount: "1"),
                    .init(name: "Baking powder", amount: "2 tsp"),
                    .init(name: "Salt", amount: "1/4 tsp"),
                    .init(name: "Sugar", amount: "1 tbsp"),
                    .init(name: "Butter", amount: "2 tbsp")
                ]
            ),
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

    func createPhotoObjects(
        _ context: ModelContext,
        assets: [SamplePhotoAsset],
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> [PhotoObject] {
        assets.enumerated().map { offset, asset in
            createPhotoObject(
                context,
                asset: asset,
                order: offset + RecipeConstants.firstOrder,
                remotePhotoDataMap: remotePhotoDataMap
            )
        }
    }

    func ingredientObjects(
        _ context: ModelContext,
        items: [PreviewIngredient]
    ) -> [IngredientObject] {
        items.enumerated().map { offset, item in
            .create(
                context: context,
                ingredient: item.name,
                amount: item.amount,
                order: offset + RecipeConstants.firstOrder
            )
        }
    }
}
