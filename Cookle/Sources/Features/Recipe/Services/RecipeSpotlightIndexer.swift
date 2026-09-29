import AppIntents
import CoreSpotlight
import Foundation
import OSLog
import SwiftData
import UIKit

/// Keeps saved recipes in Cookle's Spotlight index as `RecipeEntity` values.
///
/// Each refresh replaces the whole recipe set, so creates, edits, deletes,
/// imports, and tag renames all converge without tracking which recipe
/// changed. A save to the main context schedules a refresh, and becoming
/// active schedules one for recipes that arrived through iCloud meanwhile.
/// Refreshes run one at a time and repeat while another was requested.
@MainActor
final class RecipeSpotlightIndexer {
    /// The named index Apple recommends over the default one for app content.
    static let indexName = "CookleRecipes"

    private static let logger = Logger(subsystem: "Cookle", category: "RecipeSpotlight")

    private let modelContainer: ModelContainer
    private var refreshTask: Task<Void, Never>?
    private var isRefreshPending = false
    private var saveObserver: (any NSObjectProtocol)?
    private var activationObserver: (any NSObjectProtocol)?

    /// Creates the indexer.
    ///
    /// - Parameter isEnabled: Pass `false` for previews and capture runs so
    ///   their sample recipes never reach the device's Spotlight index.
    init(
        modelContainer: ModelContainer,
        isEnabled: Bool
    ) {
        self.modelContainer = modelContainer
        guard isEnabled else {
            return
        }
        saveObserver = NotificationCenter.default.addObserver(
            forName: ModelContext.didSave,
            object: modelContainer.mainContext,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scheduleRefresh()
            }
        }
        activationObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.scheduleRefresh()
            }
        }
        // The live assembly is built after launch activation, so the first
        // refresh cannot wait for an activation notification.
        scheduleRefresh()
    }

    /// Replaces every indexed recipe with the recipes currently saved.
    static func replaceIndex(
        context: ModelContext
    ) async throws {
        let entities = try context.fetch(
            .recipes(.all)
        )
        .compactMap(RecipeEntity.init)
        let index = CSSearchableIndex(name: indexName)
        try await index.deleteAppEntities(ofType: RecipeEntity.self)
        try await index.indexAppEntities(entities)
        logger.notice("replaced recipe spotlight index count=\(entities.count, privacy: .public)")
    }

    /// Reindexes the given recipes and removes identifiers that no longer
    /// resolve to a saved recipe.
    static func reindex(
        identifiers: [RecipeEntity.ID],
        entities: [RecipeEntity]
    ) async throws {
        let index = CSSearchableIndex(name: indexName)
        let resolvedIdentifiers = Set(entities.map(\.id))
        let missingIdentifiers = identifiers.filter { identifier in
            !resolvedIdentifiers.contains(identifier)
        }
        if !missingIdentifiers.isEmpty {
            try await index.deleteAppEntities(
                identifiedBy: missingIdentifiers,
                ofType: RecipeEntity.self
            )
        }
        try await index.indexAppEntities(entities)
    }
}

private extension RecipeSpotlightIndexer {
    func scheduleRefresh() {
        isRefreshPending = true
        guard refreshTask == nil else {
            return
        }
        refreshTask = Task { [weak self] in
            await self?.runRefreshLoop()
        }
    }

    func runRefreshLoop() async {
        while isRefreshPending {
            isRefreshPending = false
            do {
                try await Self.replaceIndex(
                    context: modelContainer.mainContext
                )
            } catch {
                Self.logger.error(
                    "failed to refresh recipe spotlight index: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
        refreshTask = nil
    }
}
