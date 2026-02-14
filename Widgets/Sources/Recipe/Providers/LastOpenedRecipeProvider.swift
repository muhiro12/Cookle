import CookleLibrary
import SwiftData
import UIKit
import WidgetKit

struct LastOpenedRecipeProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> RecipeEntry {
        .init(date: .now, titleText: "Last Opened", image: nil)
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
        var entries: [RecipeEntry] = .init()
        do {
            let context = try ModelContainerFactory.sharedContext()
            for hour in 0 ..< 5 {
                if let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) {
                    let entry = (try? makeEntry(date: date, context: context)) ?? makeErrorEntry(date: date)
                    entries.append(entry)
                }
            }
        } catch {
            for hour in 0 ..< 5 {
                if let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) {
                    entries.append(makeErrorEntry(date: date))
                }
            }
        }
        return .init(entries: entries, policy: .atEnd)
    }

    private func makeEntry(date: Date, context: ModelContext) throws -> RecipeEntry {
        if let recipe = try RecipeService.lastOpenedRecipe(context: context) {
            let photo = recipe.photoObjects?.min()?.photo
            let image = photo.flatMap { UIImage(data: $0.data) }
            return .init(date: date, titleText: recipe.name, image: image)
        }
        return .init(date: date, titleText: "Not Found", image: nil)
    }

    private func makeErrorEntry(date: Date) -> RecipeEntry {
        .init(date: date, titleText: "Error", image: nil)
    }
}
