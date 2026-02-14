import CookleLibrary
import SwiftData
import WidgetKit

struct LastOpenedRecipeProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> RecipeEntry {
        .init(date: .now, titleText: "Last Opened", image: nil)
    }

    func snapshot(for _: ConfigurationAppIntent, in context: Context) -> RecipeEntry {
        do {
            let modelContext = try ModelContainerFactory.sharedContext()
            return try makeEntry(
                date: .now,
                context: modelContext,
                family: context.family
            )
        } catch {
            return makeErrorEntry(date: .now)
        }
    }

    func timeline(for _: ConfigurationAppIntent, in context: Context) -> Timeline<RecipeEntry> {
        let now = Date.now
        let entry: RecipeEntry = {
            do {
                let modelContext = try ModelContainerFactory.sharedContext()
                return try makeEntry(
                    date: now,
                    context: modelContext,
                    family: context.family
                )
            } catch {
                return makeErrorEntry(date: now)
            }
        }()

        guard let nextRefreshDate = Calendar.current.date(byAdding: .hour, value: 6, to: now) else {
            return .init(entries: [entry], policy: .atEnd)
        }
        return .init(entries: [entry], policy: .after(nextRefreshDate))
    }

    private func makeEntry(date: Date, context: ModelContext, family: WidgetFamily) throws -> RecipeEntry {
        if let recipe = try RecipeService.lastOpenedRecipe(context: context) {
            let photo = recipe.photoObjects?.min()?.photo
            let imageData = photo?.data
            let image = imageData.flatMap {
                RecipeWidgetImageLoader.makeImage(from: $0, family: family)
            }
            return .init(date: date, titleText: recipe.name, image: image)
        }
        return .init(date: date, titleText: "Not Found", image: nil)
    }

    private func makeErrorEntry(date: Date) -> RecipeEntry {
        .init(date: date, titleText: "Error", image: nil)
    }
}
