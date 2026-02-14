import CookleLibrary
import SwiftData
import UIKit
import WidgetKit

struct RandomRecipeProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> RecipeEntry {
        .init(date: .now, titleText: "Random Recipe", image: nil)
    }

    func snapshot(for _: ConfigurationAppIntent, in _: Context) -> RecipeEntry {
        do {
            let context = try ModelContainerFactory.sharedContext()
            return try makeEntry(date: .now, context: context)
        } catch {
            return makeErrorEntry(date: .now)
        }
    }

    func timeline(for _: ConfigurationAppIntent, in _: Context) -> Timeline<RecipeEntry> {
        let now = Date.now
        let entry: RecipeEntry = {
            do {
                let context = try ModelContainerFactory.sharedContext()
                return try makeEntry(date: now, context: context)
            } catch {
                return makeErrorEntry(date: now)
            }
        }()

        guard let nextRefreshDate = Calendar.current.date(byAdding: .hour, value: 6, to: now) else {
            return .init(entries: [entry], policy: .atEnd)
        }
        return .init(entries: [entry], policy: .after(nextRefreshDate))
    }

    private func makeEntry(date: Date, context: ModelContext) throws -> RecipeEntry {
        if let recipe = try RecipeService.randomRecipe(context: context) {
            let photo = recipe.photoObjects?.min()?.photo
            let image = photo.flatMap { UIImage(data: $0.data) }
            return .init(date: date, titleText: recipe.name, image: image)
        }
        return .init(date: date, titleText: "No Recipes", image: nil)
    }

    private func makeErrorEntry(date: Date) -> RecipeEntry {
        .init(date: date, titleText: "Error", image: nil)
    }
}
