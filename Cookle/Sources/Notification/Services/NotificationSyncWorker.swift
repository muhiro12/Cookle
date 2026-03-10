import Foundation
@preconcurrency import SwiftData

actor NotificationSyncWorker {
    private enum MeasurementConstants {
        static let millisecondsPerSecond = TimeInterval(
            Int("1000") ?? .zero
        )
    }

    struct Plan: Sendable {
        let preparedRequests: [PreparedSuggestionRequest]
    }

    struct PreparedSuggestionRequest: Sendable {
        let suggestion: DailyRecipeSuggestion
        let snapshot: NotificationRecipeSnapshot?
        let attachmentFileURL: URL?
    }

    private let modelContainer: ModelContainer
    private let calendar: Calendar
    private let attachmentStore: NotificationAttachmentStore
    private let logger = CookleApp.logger(
        category: "NotificationSync",
        source: #fileID
    )

    init(
        modelContainer: ModelContainer,
        calendar: Calendar = .current,
        attachmentStore: NotificationAttachmentStore = .init()
    ) {
        self.modelContainer = modelContainer
        self.calendar = calendar
        self.attachmentStore = attachmentStore
    }

    func buildPlan(
        hour: Int,
        minute: Int,
        daysAhead: Int = 14,
        now: Date = .now
    ) -> Plan {
        let snapshots = fetchRecipeSnapshots()
        let suggestions = DailyRecipeSuggestionService.buildSuggestions(
            candidates: suggestionCandidates(
                snapshots: snapshots
            ),
            hour: hour,
            minute: minute,
            now: now,
            calendar: calendar,
            daysAhead: daysAhead,
            identifierPrefix: NotificationConstants.suggestionIdentifierPrefix
        )
        let preparedRequests = prepareRequests(
            suggestions: suggestions,
            snapshots: snapshots
        )

        attachmentStore.pruneAttachments(
            keepingStableIdentifiers: Set(
                preparedRequests.compactMap { preparedRequest in
                    if preparedRequest.attachmentFileURL != nil {
                        return preparedRequest.suggestion.stableIdentifier
                    }
                    return nil
                }
            )
        )

        return .init(
            preparedRequests: preparedRequests
        )
    }

    func randomRecipeSnapshot() -> NotificationRecipeSnapshot? {
        fetchRecipeSnapshots().randomElement()
    }

    func prepareAttachmentFileURL(
        for snapshot: NotificationRecipeSnapshot
    ) -> URL? {
        attachmentStore.prepareAttachmentFileURL(
            for: snapshot
        )
    }

    func removeAllAttachments() {
        attachmentStore.removeAllAttachments()
    }
}

private extension NotificationSyncWorker {
    func fetchRecipeSnapshots() -> [NotificationRecipeSnapshot] {
        let snapshotFetchStartedAt = Date.timeIntervalSinceReferenceDate
        let context = ModelContext(modelContainer)
        guard let recipes = try? context.fetch(
            .recipes(.all)
        ) else {
            return []
        }
        let snapshots = recipes.map(NotificationRecipeSnapshot.make(recipe:))
        logger.notice(
            "notification snapshot fetch finished in \(durationMilliseconds(since: snapshotFetchStartedAt)) ms"
        )
        return snapshots
    }

    func suggestionCandidates(
        snapshots: [NotificationRecipeSnapshot]
    ) -> [DailyRecipeSuggestionCandidate] {
        snapshots.map { snapshot in
            .init(
                name: snapshot.name,
                stableIdentifier: snapshot.stableIdentifier
            )
        }
    }

    func prepareRequests(
        suggestions: [DailyRecipeSuggestion],
        snapshots: [NotificationRecipeSnapshot]
    ) -> [PreparedSuggestionRequest] {
        let attachmentBuildStartedAt = Date.timeIntervalSinceReferenceDate
        let snapshotsByStableIdentifier = Dictionary(
            uniqueKeysWithValues: snapshots.map { snapshot in
                (
                    snapshot.stableIdentifier,
                    snapshot
                )
            }
        )
        let preparedRequests = suggestions.map { suggestion in
            prepareRequest(
                suggestion: suggestion,
                snapshotsByStableIdentifier: snapshotsByStableIdentifier
            )
        }
        logger.notice(
            "attachment build finished in \(durationMilliseconds(since: attachmentBuildStartedAt)) ms"
        )
        return preparedRequests
    }

    func prepareRequest(
        suggestion: DailyRecipeSuggestion,
        snapshotsByStableIdentifier: [String: NotificationRecipeSnapshot]
    ) -> PreparedSuggestionRequest {
        let snapshot = snapshotsByStableIdentifier[
            suggestion.stableIdentifier
        ]
        let attachmentFileURL = snapshot.flatMap { resolvedSnapshot in
            attachmentStore.prepareAttachmentFileURL(
                for: resolvedSnapshot
            )
        }
        return .init(
            suggestion: suggestion,
            snapshot: snapshot,
            attachmentFileURL: attachmentFileURL
        )
    }

    func durationMilliseconds(
        since startedAt: TimeInterval
    ) -> Int {
        Int(
            (
                Date.timeIntervalSinceReferenceDate
                    - startedAt
            ) * MeasurementConstants.millisecondsPerSecond
        )
    }
}
