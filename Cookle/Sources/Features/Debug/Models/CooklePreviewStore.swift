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
    }

    private var hasPreparedPreviewData = false
    var remotePhotoDataCache = [SamplePhotoAsset: Data]()

    /// Reference date for generated diary entries. Capture runs pin this for deterministic dates.
    var baseDate = Date.now

    /// Directory holding local sample photo files, used instead of remote downloads when set.
    var localPhotoDirectoryURL: URL?

    /// Recipes created by the most recent preparation, in deterministic creation order.
    private(set) var preparedRecipes = [Recipe]()
    private(set) var preparedDiaries = [Diary]()

    let remoteImageSession: URLSession = {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.timeoutIntervalForRequest = PreviewConstants.requestTimeout
        configuration.timeoutIntervalForResource = PreviewConstants.resourceTimeout
        return .init(configuration: configuration)
    }()

    func prepare(_ context: ModelContext) throws {
        if !hasPreparedPreviewData {
            preparedDiaries = try createPreviewDiaries(context)
            hasPreparedPreviewData = true
        }
    }

    func createPreviewDiaries(_ context: ModelContext) throws -> [Diary] {
        try createPreviewDiaries(
            context,
            remotePhotoDataMap: localPhotoDataMap()
        )
    }

    func createPreviewDiariesWithRemoteImages(
        _ context: ModelContext
    ) async throws -> [Diary] {
        let remotePhotoDataMap = await fetchRemotePhotoDataMap()
        return try createPreviewDiaries(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
    }
}

private extension CooklePreviewStore {
    var previewDiaryNote: String {
        String(localized: "Preview Diary Note", table: "SampleData", bundle: .main)
    }

    func createPreviewDiaries(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> [Diary] {
        let recipes = try makePreviewRecipes(
            context,
            remotePhotoDataMap: remotePhotoDataMap
        )
        preparedRecipes = [
            recipes.spaghettiCarbonara,
            recipes.beefStew,
            recipes.chickenStirFry,
            recipes.vegetableSoup,
            recipes.pancakes
        ]
        return try Array(.zero..<PreviewConstants.diaryCount).map { dayOffset in
            try makePreviewDiary(
                context,
                dayOffset: dayOffset,
                recipes: recipes
            )
        }
    }

    private func makePreviewRecipes(
        _ context: ModelContext,
        remotePhotoDataMap: [SamplePhotoAsset: Data]
    ) throws -> PreviewRecipes {
        try .init(
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
    ) throws -> Diary {
        try DiaryOperations.createWithOutcome(
            context: context,
            input: .init(
                date: previewDate(for: dayOffset),
                breakfasts: [recipes.pancakes],
                lunches: [
                    recipes.chickenStirFry,
                    recipes.vegetableSoup
                ],
                dinners: [
                    recipes.spaghettiCarbonara,
                    recipes.beefStew
                ],
                note: previewDiaryNote
            )
        ).value
    }

    func localPhotoDataMap() -> [SamplePhotoAsset: Data] {
        guard let localPhotoDirectoryURL else {
            return .init()
        }
        return SamplePhotoAsset.allCases.reduce(
            into: [SamplePhotoAsset: Data]()
        ) { photoDataMap, samplePhotoAsset in
            let photoFileURL = localPhotoDirectoryURL.appending(
                path: samplePhotoAsset.fileName
            )
            guard let photoData = try? Data(contentsOf: photoFileURL),
                  !photoData.isEmpty else {
                return
            }
            photoDataMap[samplePhotoAsset] = photoData
        }
    }

    func previewDate(for dayOffset: Int) -> Date {
        let offsetSeconds = TimeInterval(
            -dayOffset
                * PreviewConstants.dayStride
                * PreviewConstants.hoursPerDay
                * PreviewConstants.minutesPerHour
                * PreviewConstants.secondsPerMinute
        )
        return baseDate.addingTimeInterval(offsetSeconds)
    }
}
