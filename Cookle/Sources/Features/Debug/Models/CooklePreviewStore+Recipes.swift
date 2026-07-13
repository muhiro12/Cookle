import Foundation
import SwiftData

// swiftlint:disable file_length function_body_length line_length

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
    ) throws -> Recipe {
        .create(
            context: context,
            content: .init(
                name: String(
                    localized: "Spaghetti Carbonara",
                    table: "SampleData",
                    bundle: .main
                ),
                photos: try createPhotoObjects(
                    context,
                    assets: [.spaghettiCarbonara1, .spaghettiCarbonara2],
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                servingSize: RecipeConstants.firstServingSize,
                cookingTime: RecipeConstants.mediumCookingTime,
                ingredients: try ingredientObjects(
                    context,
                    items: [
                        .init(
                            name: String(localized: "Spaghetti", table: "SampleData", bundle: .main),
                            amount: String(localized: "200g", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Eggs", table: "SampleData", bundle: .main),
                            amount: "2"
                        ),
                        .init(
                            name: String(
                                localized: "Parmesan cheese",
                                table: "SampleData",
                                bundle: .main
                            ),
                            amount: String(localized: "50g", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Pancetta", table: "SampleData", bundle: .main),
                            amount: String(localized: "100g", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Black pepper", table: "SampleData", bundle: .main),
                            amount: String(localized: "to taste", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Salt", table: "SampleData", bundle: .main),
                            amount: String(localized: "to taste", table: "SampleData", bundle: .main)
                        )
                    ]
                ),
                steps: [
                    String(
                        localized: "Boil water in a large pot and add salt.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Cook the spaghetti until al dente.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "In a separate pan, cook the pancetta until crispy.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Beat the eggs in a bowl and mix with grated Parmesan cheese.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Drain the spaghetti and mix with pancetta and the egg mixture.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Season with black pepper and serve immediately.",
                        table: "SampleData",
                        bundle: .main
                    )
                ],
                categories: [
                    try .create(
                        context: context,
                        value: String(localized: "Italian", table: "SampleData", bundle: .main)
                    )
                ],
                note: String(
                    localized: "Use freshly grated Parmesan for the best flavor.",
                    table: "SampleData",
                    bundle: .main
                )
            )
        )
    }

    func cookBeefStew(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> Recipe {
        .create(
            context: context,
            content: .init(
                name: String(localized: "Beef Stew", table: "SampleData", bundle: .main),
                photos: try createPhotoObjects(
                    context,
                    assets: [.beefStew1, .beefStew2],
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                servingSize: RecipeConstants.thirdServingSize,
                cookingTime: RecipeConstants.stewCookingTime,
                ingredients: try ingredientObjects(
                    context,
                    items: [
                        .init(
                            name: String(localized: "Beef chuck", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 kg", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Carrots", table: "SampleData", bundle: .main),
                            amount: "3"
                        ),
                        .init(
                            name: String(localized: "Potatoes", table: "SampleData", bundle: .main),
                            amount: "4"
                        ),
                        .init(
                            name: String(localized: "Onions", table: "SampleData", bundle: .main),
                            amount: "2"
                        ),
                        .init(
                            name: String(localized: "Beef broth", table: "SampleData", bundle: .main),
                            amount: String(localized: "4 cups", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Tomato paste", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 tbsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Flour", table: "SampleData", bundle: .main),
                            amount: String(localized: "1/4 cup", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Salt", table: "SampleData", bundle: .main),
                            amount: String(localized: "to taste", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Black pepper", table: "SampleData", bundle: .main),
                            amount: String(localized: "to taste", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Olive oil", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 tbsp", table: "SampleData", bundle: .main)
                        )
                    ]
                ),
                steps: [
                    String(
                        localized: "Cut the beef into large chunks and season with salt and pepper.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Heat the oil in a large pot over medium-high heat.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Brown the beef on all sides, then remove from the pot.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Add the chopped onions, carrots, and potatoes to the pot and cook for 5 minutes.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Stir in the flour and tomato paste, and cook for another minute.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Return the beef to the pot and add the beef broth.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Bring to a boil, then reduce the heat and simmer for 2 hours, until the beef is tender.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Season with salt and pepper to taste, and serve hot.",
                        table: "SampleData",
                        bundle: .main
                    )
                ],
                categories: [
                    try .create(
                        context: context,
                        value: String(localized: "Comfort Food", table: "SampleData", bundle: .main)
                    )
                ],
                note: String(
                    localized: "This stew is even better the next day.",
                    table: "SampleData",
                    bundle: .main
                )
            )
        )
    }

    func cookChickenStirFry(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> Recipe {
        .create(
            context: context,
            content: .init(
                name: String(localized: "Chicken Stir Fry", table: "SampleData", bundle: .main),
                photos: try createPhotoObjects(
                    context,
                    assets: [.chickenStirFry1, .chickenStirFry2],
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                servingSize: RecipeConstants.secondServingSize,
                cookingTime: RecipeConstants.shortCookingTime,
                ingredients: try ingredientObjects(
                    context,
                    items: [
                        .init(
                            name: String(localized: "Chicken breast", table: "SampleData", bundle: .main),
                            amount: String(localized: "500g", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Bell peppers", table: "SampleData", bundle: .main),
                            amount: "2"
                        ),
                        .init(
                            name: String(localized: "Broccoli", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 head", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Soy sauce", table: "SampleData", bundle: .main),
                            amount: String(localized: "3 tbsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Garlic", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 cloves", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Ginger", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 inch", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Vegetable oil", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 tbsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Cornstarch", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 tbsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Water", table: "SampleData", bundle: .main),
                            amount: String(localized: "1/2 cup", table: "SampleData", bundle: .main)
                        )
                    ]
                ),
                steps: [
                    String(
                        localized: "Cut the chicken into bite-sized pieces.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Chop the bell peppers and broccoli into small pieces.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Heat the oil in a large skillet over medium-high heat.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Add the chicken and cook until browned.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Add the garlic and ginger, and cook for another minute.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Add the bell peppers and broccoli, and cook until tender.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Mix the soy sauce, cornstarch, and water in a small bowl.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Pour the sauce over the chicken and vegetables, and cook until thickened.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Serve hot with rice.",
                        table: "SampleData",
                        bundle: .main
                    )
                ],
                categories: [
                    try .create(
                        context: context,
                        value: String(localized: "Asian", table: "SampleData", bundle: .main)
                    )
                ],
                note: String(
                    localized: "You can use any vegetables you like for this stir fry.",
                    table: "SampleData",
                    bundle: .main
                )
            )
        )
    }

    func cookVegetableSoup(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> Recipe {
        .create(
            context: context,
            content: .init(
                name: String(localized: "Vegetable Soup", table: "SampleData", bundle: .main),
                photos: try createPhotoObjects(
                    context,
                    assets: [.vegetableSoup1, .vegetableSoup2],
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                servingSize: RecipeConstants.secondServingSize,
                cookingTime: RecipeConstants.longCookingTime,
                ingredients: try ingredientObjects(
                    context,
                    items: [
                        .init(
                            name: String(localized: "Carrots", table: "SampleData", bundle: .main),
                            amount: "3"
                        ),
                        .init(
                            name: String(localized: "Potatoes", table: "SampleData", bundle: .main),
                            amount: "2"
                        ),
                        .init(
                            name: String(localized: "Celery", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 stalks", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Onion", table: "SampleData", bundle: .main),
                            amount: "1"
                        ),
                        .init(
                            name: String(localized: "Garlic", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 cloves", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Vegetable broth", table: "SampleData", bundle: .main),
                            amount: String(localized: "6 cups", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Tomatoes", table: "SampleData", bundle: .main),
                            amount: "2"
                        ),
                        .init(
                            name: String(localized: "Salt", table: "SampleData", bundle: .main),
                            amount: String(localized: "to taste", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Black pepper", table: "SampleData", bundle: .main),
                            amount: String(localized: "to taste", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Olive oil", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 tbsp", table: "SampleData", bundle: .main)
                        )
                    ]
                ),
                steps: [
                    String(
                        localized: "Chop the carrots, potatoes, celery, onion, and tomatoes.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Heat the oil in a large pot over medium heat.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Add the chopped onions and garlic, and sauté until golden brown.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Add the carrots, potatoes, and celery, and cook for another 5 minutes.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Pour in the vegetable broth and bring to a boil.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Reduce the heat and simmer for 20 minutes, until the vegetables are tender.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Season with salt and pepper to taste.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Serve hot with a sprinkle of fresh herbs.",
                        table: "SampleData",
                        bundle: .main
                    )
                ],
                categories: [
                    try .create(
                        context: context,
                        value: String(localized: "Healthy", table: "SampleData", bundle: .main)
                    )
                ],
                note: String(
                    localized: "You can add any vegetables you have on hand.",
                    table: "SampleData",
                    bundle: .main
                )
            )
        )
    }

    func cookPancakes(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> Recipe {
        .create(
            context: context,
            content: .init(
                name: String(localized: "Pancakes", table: "SampleData", bundle: .main),
                photos: try createPhotoObjects(
                    context,
                    assets: [.pancakes1, .pancakes2],
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                servingSize: RecipeConstants.secondServingSize,
                cookingTime: RecipeConstants.shortCookingTime,
                ingredients: try ingredientObjects(
                    context,
                    items: [
                        .init(
                            name: String(localized: "All-purpose flour", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 cup", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Milk", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 cup", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Egg", table: "SampleData", bundle: .main),
                            amount: "1"
                        ),
                        .init(
                            name: String(localized: "Baking powder", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 tsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Salt", table: "SampleData", bundle: .main),
                            amount: String(localized: "1/4 tsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Sugar", table: "SampleData", bundle: .main),
                            amount: String(localized: "1 tbsp", table: "SampleData", bundle: .main)
                        ),
                        .init(
                            name: String(localized: "Butter", table: "SampleData", bundle: .main),
                            amount: String(localized: "2 tbsp", table: "SampleData", bundle: .main)
                        )
                    ]
                ),
                steps: [
                    String(
                        localized: "In a large bowl, mix together the flour, baking powder, salt, and sugar.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Make a well in the center and pour in the milk, egg, and melted butter.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Mix until smooth.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Heat a lightly oiled griddle or frying pan over medium-high heat.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Pour or scoop the batter onto the griddle, using approximately 1/4 cup for each pancake.",
                        table: "SampleData",
                        bundle: .main
                    ),
                    String(
                        localized: "Brown on both sides and serve hot.",
                        table: "SampleData",
                        bundle: .main
                    )
                ],
                categories: [
                    try .create(
                        context: context,
                        value: String(localized: "Breakfast", table: "SampleData", bundle: .main)
                    )
                ],
                note: String(
                    localized: "Serve with syrup, butter, and fresh fruits.",
                    table: "SampleData",
                    bundle: .main
                )
            )
        )
    }

    func createPhotoObjects(
        _ context: ModelContext,
        assets: [SamplePhotoAsset],
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> [PhotoObject] {
        try assets.enumerated().map { offset, asset in
            try createPhotoObject(
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
    ) throws -> [IngredientObject] {
        try items.enumerated().map { offset, item in
            try .create(
                context: context,
                ingredient: item.name,
                amount: item.amount,
                order: offset + RecipeConstants.firstOrder
            )
        }
    }
}

// swiftlint:enable file_length function_body_length line_length
