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
    private struct PreviewRecipes {
        let pancakes: Recipe
        let chickenStirFry: Recipe
        let vegetableSoup: Recipe
        let spaghettiCarbonara: Recipe
        let beefStew: Recipe
    }

    private enum PreviewConstants {
        static let requestTimeout: TimeInterval = 5
        static let resourceTimeout: TimeInterval = 10
        static let diaryCount = 10
        static let dayStride = 8
        static let hoursPerDay = 24
        static let minutesPerHour = 60
        static let secondsPerMinute = 60
        static let firstOrder = 1
        static let secondOrder = 2
    }

    private var hasPreparedPreviewData = false
    var remotePhotoDataCache = [SamplePhotoAsset: Data]()

    let remoteImageSession: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.timeoutIntervalForRequest = PreviewConstants.requestTimeout
        configuration.timeoutIntervalForResource = PreviewConstants.resourceTimeout
        return .init(configuration: configuration)
    }()

    func prepare(_ context: ModelContext) {
        if !hasPreparedPreviewData {
            _ = createPreviewDiaries(context)
            hasPreparedPreviewData = true
        }
    }

    func createPreviewDiaries(_ context: ModelContext) -> [Diary] {
        createPreviewDiaries(
            context,
            remotePhotoDataMap: .init()
        )
    }

    func createPreviewDiariesWithRemoteImages(_ context: ModelContext) async -> [Diary] {
        let remotePhotoDataMap = await fetchRemotePhotoDataMap()
        return createPreviewDiaries(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
    }
}

private extension CooklePreviewStore {
    var previewDiaryNote: String {
        """
          Today's menu:
          - Breakfast: Delicious pancakes served with syrup, butter, and fresh fruits.
          - Lunch: Chicken stir fry with bell peppers and broccoli, accompanied by a hearty vegetable soup.
          - Dinner: Classic spaghetti carbonara and warm beef stew for a comforting end to the day.

          Tips:
          - Try adding blueberries or bananas to the pancakes for extra flavor.
          - The vegetable soup can be stored for up to 3 days, making it perfect for leftovers.
          - The beef stew tastes even better the next day, so make extra for an easy meal tomorrow.
          """
    }

    func createPreviewDiaries(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> [Diary] {
        let recipes = makePreviewRecipes(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        return Array(.zero..<PreviewConstants.diaryCount).map { dayOffset in
            makePreviewDiary(
                context,
                dayOffset: dayOffset,
                recipes: recipes
            )
        }
    }

    private func makePreviewRecipes(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) -> PreviewRecipes {
        .init(
            pancakes: cookPancakes(
                context,
                remotePhotoDataMap: remotePhotoDataMap
            ),
            chickenStirFry: cookChickenStirFry(
                context,
                remotePhotoDataMap: remotePhotoDataMap
            ),
            vegetableSoup: cookVegetableSoup(
                context,
                remotePhotoDataMap: remotePhotoDataMap
            ),
            spaghettiCarbonara: cookSpaghettiCarbonara(
                context,
                remotePhotoDataMap: remotePhotoDataMap
            ),
            beefStew: cookBeefStew(
                context,
                remotePhotoDataMap: remotePhotoDataMap
            )
        )
    }

    private func makePreviewDiary(
        _ context: ModelContext,
        dayOffset: Int,
        recipes: PreviewRecipes
    ) -> Diary {
        .create(
            context: context,
            date: previewDate(for: dayOffset),
            objects: previewDiaryObjects(
                context,
                recipes: recipes
            ),
            note: previewDiaryNote
        )
    }

    func previewDate(for dayOffset: Int) -> Date {
        let offsetSeconds = TimeInterval(
            -dayOffset
                * PreviewConstants.dayStride
                * PreviewConstants.hoursPerDay
                * PreviewConstants.minutesPerHour
                * PreviewConstants.secondsPerMinute
        )
        return .now.addingTimeInterval(offsetSeconds)
    }

    private func previewDiaryObjects(
        _ context: ModelContext,
        recipes: PreviewRecipes
    ) -> [DiaryObject] {
        [
            .create(
                context: context,
                recipe: recipes.pancakes,
                type: .breakfast,
                order: PreviewConstants.firstOrder
            ),
            .create(
                context: context,
                recipe: recipes.chickenStirFry,
                type: .lunch,
                order: PreviewConstants.firstOrder
            ),
            .create(
                context: context,
                recipe: recipes.vegetableSoup,
                type: .lunch,
                order: PreviewConstants.secondOrder
            ),
            .create(
                context: context,
                recipe: recipes.spaghettiCarbonara,
                type: .dinner,
                order: PreviewConstants.firstOrder
            ),
            .create(
                context: context,
                recipe: recipes.beefStew,
                type: .dinner,
                order: PreviewConstants.secondOrder
            )
        ]
    }
}
