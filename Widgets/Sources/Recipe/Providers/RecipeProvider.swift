import CookleLibrary
import SwiftData
import WidgetKit

struct RecipeProvider: AppIntentTimelineProvider {
    func placeholder(in _: Context) -> RecipeEntry {
        .init(
            date: .now,
            titleText: "Recipe",
            image: nil,
            deepLinkURL: CookleDeepLinkURLBuilder.recipeURL()
        )
    }

    func snapshot(for configuration: RecipeConfigurationAppIntent, in context: Context) -> RecipeEntry {
        do {
            let modelContext = try ModelContainerFactory.sharedContext()
            return try makeEntry(
                date: .now,
                context: modelContext,
                family: context.family,
                selection: configuration.selection
            )
        } catch {
            return makeErrorEntry(date: .now)
        }
    }

    func timeline(for configuration: RecipeConfigurationAppIntent, in context: Context) -> Timeline<RecipeEntry> {
        let now = Date.now
        let entry: RecipeEntry = {
            do {
                let modelContext = try ModelContainerFactory.sharedContext()
                return try makeEntry(
                    date: now,
                    context: modelContext,
                    family: context.family,
                    selection: configuration.selection
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
}

private extension RecipeProvider {
    func makeEntry(date: Date,
                   context: ModelContext,
                   family: WidgetFamily,
                   selection: RecipeWidgetSelection) throws -> RecipeEntry {
        if let recipe = try recipe(for: selection, context: context) {
            let photo = recipe.photoObjects?.min()?.photo
            let imageData = photo?.data
            let image = imageData.flatMap {
                RecipeWidgetImageLoader.makeImage(from: $0, family: family)
            }
            let deepLinkURL: URL = {
                if let recipeID = try? recipe.id.base64Encoded() {
                    return CookleDeepLinkURLBuilder.preferredRecipeDetailURL(
                        for: recipeID
                    )
                }
                return CookleDeepLinkURLBuilder.preferredRecipeURL()
            }()
            return .init(
                date: date,
                titleText: recipe.name,
                image: image,
                deepLinkURL: deepLinkURL
            )
        }
        return .init(
            date: date,
            titleText: emptyTitle(for: selection),
            image: nil,
            deepLinkURL: CookleDeepLinkURLBuilder.recipeURL()
        )
    }

    func recipe(for selection: RecipeWidgetSelection, context: ModelContext) throws -> Recipe? {
        switch selection {
        case .latest:
            return try RecipeService.latestRecipe(context: context)
        case .lastOpened:
            return try RecipeService.lastOpenedRecipe(context: context)
        case .random:
            return try RecipeService.randomRecipe(context: context)
        }
    }

    func emptyTitle(for selection: RecipeWidgetSelection) -> String {
        switch selection {
        case .lastOpened:
            return "Not Found"
        case .latest,
             .random:
            return "No Recipes"
        }
    }

    func makeErrorEntry(date: Date) -> RecipeEntry {
        .init(
            date: date,
            titleText: "Error",
            image: nil,
            deepLinkURL: CookleDeepLinkURLBuilder.recipeURL()
        )
    }
}
