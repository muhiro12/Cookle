import CookleLibrary
import SwiftData
import UIKit
import WidgetKit

struct LastOpenedRecipeProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> RecipeEntry {
        .init(date: .now, titleText: "Last Opened", image: nil)
    }

    func snapshot(for _: ConfigurationAppIntent, in _: Context) -> RecipeEntry {
        makeEntry(date: .now)
    }

    func timeline(for _: ConfigurationAppIntent, in _: Context) -> Timeline<RecipeEntry> {
        let now = Date.now
        var entries: [RecipeEntry] = .init()
        for hour in 0 ..< 5 {
            if let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) {
                entries.append(makeEntry(date: date))
            }
        }
        return .init(entries: entries, policy: .atEnd)
    }

    private func makeEntry(date: Date) -> RecipeEntry {
        do {
            let context = try ModelContainerFactory.sharedContext()
            if let recipe = try RecipeService.lastOpenedRecipe(context: context) {
                let photo = recipe.photoObjects?.min()?.photo
                let image = photo.flatMap { UIImage(data: $0.data) }
                return .init(date: date, titleText: recipe.name, image: image)
            }
            return .init(date: date, titleText: "Not Found", image: nil)
        } catch {
            return .init(date: date, titleText: "Error", image: nil)
        }
    }
}
