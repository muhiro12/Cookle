//
//  CooklePreviewStore.swift
//
//
//  Created by Hiromu Nakano on 2024/06/05.
//

import SwiftData
import SwiftUI

@Observable
@MainActor
final class CooklePreviewStore {
    private(set) var diaries = [Diary]()
    private(set) var diaryObjects = [DiaryObject]()
    private(set) var recipes = [Recipe]()
    private(set) var photos = [Photo]()
    private(set) var photoObjects = [PhotoObject]()
    private(set) var ingredients = [Ingredient]()
    private(set) var ingredientObjects = [IngredientObject]()
    private(set) var categories = [Category]()

    private var isReady: Bool {
        !diaries.isEmpty
            && !diaryObjects.isEmpty
            && !recipes.isEmpty
            && !photos.isEmpty
            && !photoObjects.isEmpty
            && !ingredients.isEmpty
            && !ingredientObjects.isEmpty
            && !categories.isEmpty
    }

    @MainActor
    func prepare(_ container: ModelContainer) async {
        _ = try! await createPreviewDiaries(container, isPreview: true)
        while !isReady {
            try! await Task.sleep(for: .seconds(0.2))
            diaries = try! container.mainContext.fetch(.diaries(.all))
            diaryObjects = try! container.mainContext.fetch(.diaryObjects(.all))
            recipes = try! container.mainContext.fetch(.recipes(.all))
            photos = try! container.mainContext.fetch(.photos(.all))
            photoObjects = try! container.mainContext.fetch(.photoObjects(.all))
            ingredients = try! container.mainContext.fetch(.ingredients(.all))
            ingredientObjects = try! container.mainContext.fetch(.ingredientObjects(.all))
            categories = try! container.mainContext.fetch(.categories(.all))
        }
    }

    @MainActor
    func createPreviewDiaries(_ container: ModelContainer, isPreview: Bool = false) async throws -> [Diary] {
        let pancakes = try await cookPancakes(container, isPreview: isPreview)
        let chickenStirFry = try await cookChickenStirFry(container, isPreview: isPreview)
        let vegetableSoup = try await cookVegetableSoup(container, isPreview: isPreview)
        let spaghettiCarbonara = try await cookSpaghettiCarbonara(container, isPreview: isPreview)
        let beefStew = try await cookBeefStew(container, isPreview: isPreview)
        return (0..<10).map { i in
            .create(
                container: container,
                date: .now.addingTimeInterval(TimeInterval(-i * 8) * 24 * 60 * 60),
                objects: [
                    .create(
                        container: container,
                        recipe: pancakes,
                        type: .breakfast,
                        order: 1
                    ),
                    .create(
                        container: container,
                        recipe: chickenStirFry,
                        type: .lunch,
                        order: 1
                    ),
                    .create(
                        container: container,
                        recipe: vegetableSoup,
                        type: .lunch,
                        order: 2
                    ),
                    .create(
                        container: container,
                        recipe: spaghettiCarbonara,
                        type: .dinner,
                        order: 1
                    ),
                    .create(
                        container: container,
                        recipe: beefStew,
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
    }

    @MainActor
    private func cookSpaghettiCarbonara(_ container: ModelContainer, isPreview: Bool) async throws -> Recipe {
        return .create(
            container: container,
            name: "Spaghetti Carbonara",
            photos: [
                isPreview ? createPhotoObject(container, systemName: "frying.pan", order: 1) : try await createPhotoObject(container, name: "SpaghettiCarbonara1", order: 1),
                isPreview ? createPhotoObject(container, systemName: "oval.portrait", order: 2) : try await createPhotoObject(container, name: "SpaghettiCarbonara2", order: 2)
            ],
            servingSize: 2,
            cookingTime: 30,
            ingredients: [
                .create(container: container, ingredient: "Spaghetti", amount: "200g", order: 1),
                .create(container: container, ingredient: "Eggs", amount: "2", order: 2),
                .create(container: container, ingredient: "Parmesan cheese", amount: "50g", order: 3),
                .create(container: container, ingredient: "Pancetta", amount: "100g", order: 4),
                .create(container: container, ingredient: "Black pepper", amount: "to taste", order: 5),
                .create(container: container, ingredient: "Salt", amount: "to taste", order: 6)
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
                .create(container: container, value: "Italian")
            ],
            note: "Use freshly grated Parmesan for the best flavor."
        )
    }

    @MainActor
    private func cookBeefStew(_ container: ModelContainer, isPreview: Bool) async throws -> Recipe {
        return .create(
            container: container,
            name: "Beef Stew",
            photos: [
                isPreview ? createPhotoObject(container, systemName: "fork.knife", order: 1) : try await createPhotoObject(container, name: "BeefStew1", order: 1),
                isPreview ? createPhotoObject(container, systemName: "wineglass", order: 2) : try await createPhotoObject(container, name: "BeefStew2", order: 2)
            ],
            servingSize: 6,
            cookingTime: 120,
            ingredients: [
                .create(container: container, ingredient: "Beef chuck", amount: "1 kg", order: 1),
                .create(container: container, ingredient: "Carrots", amount: "3", order: 2),
                .create(container: container, ingredient: "Potatoes", amount: "4", order: 3),
                .create(container: container, ingredient: "Onions", amount: "2", order: 4),
                .create(container: container, ingredient: "Beef broth", amount: "4 cups", order: 5),
                .create(container: container, ingredient: "Tomato paste", amount: "2 tbsp", order: 6),
                .create(container: container, ingredient: "Flour", amount: "1/4 cup", order: 7),
                .create(container: container, ingredient: "Salt", amount: "to taste", order: 8),
                .create(container: container, ingredient: "Black pepper", amount: "to taste", order: 9),
                .create(container: container, ingredient: "Olive oil", amount: "2 tbsp", order: 10)
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
                .create(container: container, value: "Comfort Food")
            ],
            note: "This stew is even better the next day."
        )
    }

    @MainActor
    private func cookChickenStirFry(_ container: ModelContainer, isPreview: Bool) async throws -> Recipe {
        return .create(
            container: container,
            name: "Chicken Stir Fry",
            photos: [
                isPreview ? createPhotoObject(container, systemName: "bird", order: 1) : try await createPhotoObject(container, name: "ChickenStirFry1", order: 1),
                isPreview ? createPhotoObject(container, systemName: "tree", order: 2) : try await createPhotoObject(container, name: "ChickenStirFry2", order: 2)
            ],
            servingSize: 4,
            cookingTime: 20,
            ingredients: [
                .create(container: container, ingredient: "Chicken breast", amount: "500g", order: 1),
                .create(container: container, ingredient: "Bell peppers", amount: "2", order: 2),
                .create(container: container, ingredient: "Broccoli", amount: "1 head", order: 3),
                .create(container: container, ingredient: "Soy sauce", amount: "3 tbsp", order: 4),
                .create(container: container, ingredient: "Garlic", amount: "2 cloves", order: 5),
                .create(container: container, ingredient: "Ginger", amount: "1 inch", order: 6),
                .create(container: container, ingredient: "Vegetable oil", amount: "2 tbsp", order: 7),
                .create(container: container, ingredient: "Cornstarch", amount: "1 tbsp", order: 8),
                .create(container: container, ingredient: "Water", amount: "1/2 cup", order: 9)
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
                .create(container: container, value: "Asian")
            ],
            note: "You can use any vegetables you like for this stir fry."
        )
    }

    @MainActor
    private func cookVegetableSoup(_ container: ModelContainer, isPreview: Bool) async throws -> Recipe {
        return .create(
            container: container,
            name: "Vegetable Soup",
            photos: [
                isPreview ? createPhotoObject(container, systemName: "cup.and.saucer", order: 1) : try await createPhotoObject(container, name: "VegetableSoup1", order: 1),
                isPreview ? createPhotoObject(container, systemName: "carrot", order: 2) : try await createPhotoObject(container, name: "VegetableSoup2", order: 2)
            ],
            servingSize: 4,
            cookingTime: 40,
            ingredients: [
                .create(container: container, ingredient: "Carrots", amount: "3", order: 1),
                .create(container: container, ingredient: "Potatoes", amount: "2", order: 2),
                .create(container: container, ingredient: "Celery", amount: "2 stalks", order: 3),
                .create(container: container, ingredient: "Onion", amount: "1", order: 4),
                .create(container: container, ingredient: "Garlic", amount: "2 cloves", order: 5),
                .create(container: container, ingredient: "Vegetable broth", amount: "6 cups", order: 6),
                .create(container: container, ingredient: "Tomatoes", amount: "2", order: 7),
                .create(container: container, ingredient: "Salt", amount: "to taste", order: 8),
                .create(container: container, ingredient: "Black pepper", amount: "to taste", order: 9),
                .create(container: container, ingredient: "Olive oil", amount: "2 tbsp", order: 10)
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
                .create(container: container, value: "Healthy")
            ],
            note: "You can add any vegetables you have on hand."
        )
    }

    @MainActor
    private func cookPancakes(_ container: ModelContainer, isPreview: Bool) async throws -> Recipe {
        return .create(
            container: container,
            name: "Pancakes",
            photos: [
                isPreview ? createPhotoObject(container, systemName: "birthday.cake", order: 1) : try await createPhotoObject(container, name: "Pancakes1", order: 1),
                isPreview ? createPhotoObject(container, systemName: "mug", order: 2) : try await createPhotoObject(container, name: "Pancakes2", order: 2)
            ],
            servingSize: 4,
            cookingTime: 20,
            ingredients: [
                .create(container: container, ingredient: "All-purpose flour", amount: "1 cup", order: 1),
                .create(container: container, ingredient: "Milk", amount: "1 cup", order: 2),
                .create(container: container, ingredient: "Egg", amount: "1", order: 3),
                .create(container: container, ingredient: "Baking powder", amount: "2 tsp", order: 4),
                .create(container: container, ingredient: "Salt", amount: "1/4 tsp", order: 5),
                .create(container: container, ingredient: "Sugar", amount: "1 tbsp", order: 6),
                .create(container: container, ingredient: "Butter", amount: "2 tbsp", order: 7)
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
                .create(container: container, value: "Breakfast")
            ],
            note: "Serve with syrup, butter, and fresh fruits."
        )
    }

    @MainActor
    private func createPhotoObject(_ container: ModelContainer, systemName: String, order: Int) -> PhotoObject {
        return .create(
            container: container,
            photoData: .init(
                data: UIImage(systemName: systemName)!.withTintColor(.init(.init(uiColor: .tintColor).adjusted(by: systemName.hashValue))).jpegData(compressionQuality: 1)!,
                source: order == 1 ? .photosPicker : .imagePlayground
            ),
            order: order
        )
    }

    @MainActor
    private func createPhotoObject(_ container: ModelContainer, name: String, order: Int) async throws -> PhotoObject {
        return .create(
            container: container,
            photoData: .init(
                data: try await URLSession.shared.data(from: .init(string: "https://raw.githubusercontent.com/muhiro12/Cookle/refs/heads/main/.Resources/\(name).png")!).0,
                source: .photosPicker
            ),
            order: order
        )
    }
}
