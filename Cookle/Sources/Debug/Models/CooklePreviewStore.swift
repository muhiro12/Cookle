//
//  CooklePreviewStore.swift
//
//
//  Created by Hiromu Nakano on 2024/06/05.
//

import Foundation
import SwiftData
import SwiftUI

final class CooklePreviewStore {
    private var hasPreparedPreviewData = false
    private var remotePhotoDataCache = [SamplePhotoAsset: Data]()

    private let remoteImageSession: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 10
        return .init(configuration: configuration)
    }()

    func prepare(_ context: ModelContext) {
        if !hasPreparedPreviewData {
            do {
                _ = try createPreviewDiaries(context)
                hasPreparedPreviewData = true
            } catch {
                assertionFailure("Failed to prepare preview data: \(error.localizedDescription)")
            }
        }
    }

    func createPreviewDiaries(_ context: ModelContext) throws -> [Diary] {
        try createPreviewDiaries(
            context,
            remotePhotoDataMap: .init()
        )
    }

    func createPreviewDiariesWithRemoteImages(_ context: ModelContext) async throws -> [Diary] {
        let remotePhotoDataMap = await fetchRemotePhotoDataMap()
        return try createPreviewDiaries(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
    }

    private func createPreviewDiaries(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> [Diary] {
        let pancakes = try cookPancakes(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        let chickenStirFry = try cookChickenStirFry(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        let vegetableSoup = try cookVegetableSoup(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        let spaghettiCarbonara = try cookSpaghettiCarbonara(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        let beefStew = try cookBeefStew(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        return (0..<10).map { dayOffset in
            .create(
                context: context,
                date: .now.addingTimeInterval(TimeInterval(-dayOffset * 8) * 24 * 60 * 60),
                objects: [
                    .create(
                        context: context,
                        recipe: pancakes,
                        type: .breakfast,
                        order: 1
                    ),
                    .create(
                        context: context,
                        recipe: chickenStirFry,
                        type: .lunch,
                        order: 1
                    ),
                    .create(
                        context: context,
                        recipe: vegetableSoup,
                        type: .lunch,
                        order: 2
                    ),
                    .create(
                        context: context,
                        recipe: spaghettiCarbonara,
                        type: .dinner,
                        order: 1
                    ),
                    .create(
                        context: context,
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

    private func cookSpaghettiCarbonara(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Spaghetti Carbonara",
            photos: [
                createPhotoObject(
                    context,
                    asset: .spaghettiCarbonara1,
                    order: 1,
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                createPhotoObject(
                    context,
                    asset: .spaghettiCarbonara2,
                    order: 2,
                    remotePhotoDataMap: remotePhotoDataMap
                )
            ],
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

    private func cookBeefStew(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Beef Stew",
            photos: [
                createPhotoObject(
                    context,
                    asset: .beefStew1,
                    order: 1,
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                createPhotoObject(
                    context,
                    asset: .beefStew2,
                    order: 2,
                    remotePhotoDataMap: remotePhotoDataMap
                )
            ],
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

    private func cookChickenStirFry(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Chicken Stir Fry",
            photos: [
                createPhotoObject(
                    context,
                    asset: .chickenStirFry1,
                    order: 1,
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                createPhotoObject(
                    context,
                    asset: .chickenStirFry2,
                    order: 2,
                    remotePhotoDataMap: remotePhotoDataMap
                )
            ],
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

    private func cookVegetableSoup(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Vegetable Soup",
            photos: [
                createPhotoObject(
                    context,
                    asset: .vegetableSoup1,
                    order: 1,
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                createPhotoObject(
                    context,
                    asset: .vegetableSoup2,
                    order: 2,
                    remotePhotoDataMap: remotePhotoDataMap
                )
            ],
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

    private func cookPancakes(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> Recipe {
        .create(
            context: context,
            name: "Pancakes",
            photos: [
                createPhotoObject(
                    context,
                    asset: .pancakes1,
                    order: 1,
                    remotePhotoDataMap: remotePhotoDataMap
                ),
                createPhotoObject(
                    context,
                    asset: .pancakes2,
                    order: 2,
                    remotePhotoDataMap: remotePhotoDataMap
                )
            ],
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
}

private extension CooklePreviewStore {
    private func createPhotoObject(_ context: ModelContext, systemName: String, order: Int) -> PhotoObject {
        let photoData = photoDataFromSystemImage(named: systemName)
        return .create(
            context: context,
            photoData: .init(
                data: photoData,
                source: order == 1 ? .photosPicker : .imagePlayground
            ),
            order: order
        )
    }

    private func createPhotoObject(
        _ context: ModelContext,
        asset: SamplePhotoAsset,
        order: Int,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> PhotoObject {
        let photoData = remotePhotoDataMap[asset]
            ?? photoDataFromSystemImage(named: asset.fallbackSystemImageName)
        return .create(
            context: context,
            photoData: .init(
                data: photoData,
                source: order == 1 ? .photosPicker : .imagePlayground
            ),
            order: order
        )
    }

    private func photoDataFromSystemImage(named systemImageName: String) -> Data {
        let tintColor: UIColor = .init(
            .init(uiColor: .tintColor).adjusted(by: systemImageName.hashValue)
        )
        if let imageData = UIImage(systemName: systemImageName)?
            .withTintColor(tintColor)
            .jpegData(compressionQuality: 1) {
            return imageData
        }
        if let fallbackImageData = UIImage(systemName: "photo")?
            .withTintColor(tintColor)
            .jpegData(compressionQuality: 1) {
            return fallbackImageData
        }
        return .init()
    }

    private func fetchRemotePhotoDataMap() async -> [SamplePhotoAsset: Data] {
        let uncachedAssets = SamplePhotoAsset.allCases.filter { samplePhotoAsset in
            remotePhotoDataCache[samplePhotoAsset] == nil
        }
        guard !uncachedAssets.isEmpty else {
            return remotePhotoDataCache
        }

        let remoteImageSession = remoteImageSession
        let fetchedPhotoPairs = await withTaskGroup(
            of: (SamplePhotoAsset, Data?).self,
            returning: [(SamplePhotoAsset, Data)].self
        ) { taskGroup in
            for samplePhotoAsset in uncachedAssets {
                let remoteImageURL = samplePhotoAsset.remoteImageURL
                taskGroup.addTask {
                    guard let remoteImageURL else {
                        return (samplePhotoAsset, nil)
                    }

                    do {
                        let (remotePhotoData, response) = try await remoteImageSession.data(from: remoteImageURL)
                        guard let httpURLResponse = response as? HTTPURLResponse else {
                            return (samplePhotoAsset, nil)
                        }
                        guard (200...299).contains(httpURLResponse.statusCode) else {
                            return (samplePhotoAsset, nil)
                        }
                        guard !remotePhotoData.isEmpty else {
                            return (samplePhotoAsset, nil)
                        }
                        return (samplePhotoAsset, remotePhotoData)
                    } catch {
                        return (samplePhotoAsset, nil)
                    }
                }
            }

            var collectedPhotoPairs = [(SamplePhotoAsset, Data)]()
            for await (samplePhotoAsset, remotePhotoData) in taskGroup {
                guard let remotePhotoData else {
                    continue
                }
                collectedPhotoPairs.append((samplePhotoAsset, remotePhotoData))
            }
            return collectedPhotoPairs
        }

        for (samplePhotoAsset, remotePhotoData) in fetchedPhotoPairs {
            remotePhotoDataCache[samplePhotoAsset] = remotePhotoData
        }
        return remotePhotoDataCache
    }
}

private enum SamplePhotoAsset: CaseIterable {
    case spaghettiCarbonara1
    case spaghettiCarbonara2
    case beefStew1
    case beefStew2
    case chickenStirFry1
    case chickenStirFry2
    case vegetableSoup1
    case vegetableSoup2
    case pancakes1
    case pancakes2

    var fileName: String {
        switch self {
        case .spaghettiCarbonara1:
            "SpaghettiCarbonara1.png"
        case .spaghettiCarbonara2:
            "SpaghettiCarbonara2.png"
        case .beefStew1:
            "BeefStew1.png"
        case .beefStew2:
            "BeefStew2.png"
        case .chickenStirFry1:
            "ChickenStirFry1.png"
        case .chickenStirFry2:
            "ChickenStirFry2.png"
        case .vegetableSoup1:
            "VegetableSoup1.png"
        case .vegetableSoup2:
            "VegetableSoup2.png"
        case .pancakes1:
            "Pancakes1.png"
        case .pancakes2:
            "Pancakes2.png"
        }
    }

    var fallbackSystemImageName: String {
        switch self {
        case .spaghettiCarbonara1:
            "frying.pan"
        case .spaghettiCarbonara2:
            "oval.portrait"
        case .beefStew1:
            "fork.knife"
        case .beefStew2:
            "wineglass"
        case .chickenStirFry1:
            "bird"
        case .chickenStirFry2:
            "tree"
        case .vegetableSoup1:
            "cup.and.saucer"
        case .vegetableSoup2:
            "carrot"
        case .pancakes1:
            "birthday.cake"
        case .pancakes2:
            "mug"
        }
    }

    var remoteImageURL: URL? {
        .init(
            string: "https://raw.githubusercontent.com/muhiro12/Cookle/main/.Resources/\(fileName)"
        )
    }
}
