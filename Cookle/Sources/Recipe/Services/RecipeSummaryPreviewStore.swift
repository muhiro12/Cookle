import Foundation
import FoundationModels
import SwiftData

@MainActor
@Observable
final class RecipeSummaryPreviewStore {
    private struct RecipeSummaryRevision: Hashable {
        let recipeID: PersistentIdentifier
        let modifiedTimestamp: Date
    }

    private struct RecipeSummaryPayload {
        let name: String
        let ingredients: [String]
        let steps: [String]
        let categories: [String]
        let note: String

        var hasContent: Bool {
            name.isNotEmpty
                || ingredients.isNotEmpty
                || steps.isNotEmpty
                || categories.isNotEmpty
                || note.isNotEmpty
        }

        @available(iOS 26.0, *)
        var request: RecipeSummaryRequest {
            .init(
                name: name,
                ingredients: ingredients,
                steps: steps,
                categories: categories,
                note: note
            )
        }
    }

    private struct RecipeSummaryJob {
        let revision: RecipeSummaryRevision
        let payload: RecipeSummaryPayload
    }

    private enum AvailabilityState {
        case enabled
        case disabledForSession
        case cooldown(until: Date)
    }

    private enum RecipeSummaryJobResult {
        case success(String)
        case disabledForSession
        case cooldown(until: Date)
        case failed
    }

    private let modelNotReadyCooldown: TimeInterval = 60

    private var cachedSummaries = [RecipeSummaryRevision: String]()
    private var loadingRecipeIDs = Set<PersistentIdentifier>()
    private var failedRecipeRevisions = Set<RecipeSummaryRevision>()
    private var queuedRecipeRevisions = [RecipeSummaryRevision]()
    private var queuedJobs = [RecipeSummaryRevision: RecipeSummaryJob]()
    private var latestRequestedRevisions = [PersistentIdentifier: RecipeSummaryRevision]()
    private var availabilityState = AvailabilityState.enabled
    private var isProcessingQueue = false
    private var currentProcessingRevision: RecipeSummaryRevision?
    private var cooldownResumeTask: Task<Void, Never>?

    func summary(for recipe: Recipe) -> String? {
        cachedSummaries[Self.revision(for: recipe)]
    }

    func requestSummaryIfNeeded(for recipe: Recipe) {
        guard #available(iOS 26.0, *) else {
            return
        }

        let revision = Self.revision(for: recipe)
        removeStaleEntries(for: recipe.persistentModelID, keeping: revision)

        switch availabilityState {
        case .disabledForSession:
            return
        case .enabled,
             .cooldown:
            break
        }

        guard cachedSummaries[revision] == nil else {
            return
        }
        guard failedRecipeRevisions.contains(revision) == false else {
            return
        }
        guard queuedJobs[revision] == nil else {
            return
        }
        guard currentProcessingRevision != revision else {
            return
        }

        let payload = Self.payload(for: recipe)
        guard payload.hasContent else {
            failedRecipeRevisions.insert(revision)
            return
        }

        latestRequestedRevisions[recipe.persistentModelID] = revision
        loadingRecipeIDs.insert(recipe.persistentModelID)
        let job = RecipeSummaryJob(revision: revision, payload: payload)
        queuedJobs[revision] = job
        queuedRecipeRevisions.append(revision)
        startQueueIfNeeded()
    }
}

private extension RecipeSummaryPreviewStore {
    private static func revision(for recipe: Recipe) -> RecipeSummaryRevision {
        .init(
            recipeID: recipe.persistentModelID,
            modifiedTimestamp: recipe.modifiedTimestamp
        )
    }

    private static func payload(for recipe: Recipe) -> RecipeSummaryPayload {
        let name = recipe.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ingredientObjects: [IngredientObject] = recipe.ingredientObjects?.sorted() ?? []
        var ingredients = [String]()
        for object in ingredientObjects {
            guard let value = object.ingredient?.value else {
                continue
            }
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedValue.isNotEmpty else {
                continue
            }
            ingredients.append(trimmedValue)
        }
        let steps = recipe.steps.compactMap { step in
            let trimmedStep = step.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedStep.isNotEmpty ? trimmedStep : nil
        }
        let categories = recipe.categories?.compactMap { category in
            let trimmedCategory = category.value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedCategory.isNotEmpty ? trimmedCategory : nil
        } ?? .empty
        let note = recipe.note.trimmingCharacters(in: .whitespacesAndNewlines)

        return .init(
            name: name,
            ingredients: ingredients,
            steps: steps,
            categories: categories,
            note: note
        )
    }

    private func removeStaleEntries(
        for recipeID: PersistentIdentifier,
        keeping currentRevision: RecipeSummaryRevision
    ) {
        cachedSummaries = cachedSummaries.filter { element in
            element.key.recipeID != recipeID || element.key == currentRevision
        }
        failedRecipeRevisions = failedRecipeRevisions.filter { revision in
            revision.recipeID != recipeID || revision == currentRevision
        }
        queuedJobs = queuedJobs.filter { element in
            element.key.recipeID != recipeID || element.key == currentRevision
        }
        queuedRecipeRevisions.removeAll { revision in
            revision.recipeID == recipeID && revision != currentRevision
        }
    }

    private func startQueueIfNeeded() {
        guard isProcessingQueue == false else {
            return
        }
        guard queuedRecipeRevisions.isNotEmpty else {
            return
        }

        refreshAvailabilityStateIfNeeded()
        switch availabilityState {
        case .enabled:
            isProcessingQueue = true
            Task {
                await processQueue()
            }
        case .disabledForSession,
             .cooldown:
            return
        }
    }

    private func processQueue() async {
        while let job = nextJob() {
            currentProcessingRevision = job.revision
            let result: RecipeSummaryJobResult
            if #available(iOS 26.0, *) {
                result = await summaryResult(for: job)
            } else {
                result = .disabledForSession
            }
            apply(result, for: job)
            currentProcessingRevision = nil
        }

        isProcessingQueue = false
        startQueueIfNeeded()
    }

    private func nextJob() -> RecipeSummaryJob? {
        refreshAvailabilityStateIfNeeded()
        switch availabilityState {
        case .enabled:
            break
        case .disabledForSession,
             .cooldown:
            return nil
        }

        while queuedRecipeRevisions.isNotEmpty {
            let revision = queuedRecipeRevisions.removeFirst()
            guard let job = queuedJobs.removeValue(forKey: revision) else {
                continue
            }
            if latestRequestedRevisions[revision.recipeID] != revision {
                finishLoadingIfNeeded(for: revision.recipeID)
                continue
            }
            return job
        }

        return nil
    }

    @available(iOS 26.0, *)
    private func summaryResult(for job: RecipeSummaryJob) async -> RecipeSummaryJobResult {
        do {
            let summary = try await RecipeService.summarize(
                request: job.payload.request
            )
            return .success(summary)
        } catch let error as RecipeSummaryError {
            switch error {
            case .modelUnavailable(let reason):
                switch reason {
                case .deviceNotEligible,
                     .appleIntelligenceNotEnabled:
                    return .disabledForSession
                case .modelNotReady:
                    return .cooldown(
                        until: .now.addingTimeInterval(modelNotReadyCooldown)
                    )
                case .none:
                    return .failed
                case .some:
                    return .failed
                }
            case .emptyRecipe,
                 .invalidResponse:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    private func apply(_ result: RecipeSummaryJobResult, for job: RecipeSummaryJob) {
        defer {
            finishLoadingIfNeeded(for: job.revision.recipeID)
        }

        guard latestRequestedRevisions[job.revision.recipeID] == job.revision else {
            return
        }

        switch result {
        case .success(let summary):
            cachedSummaries[job.revision] = summary
            failedRecipeRevisions.remove(job.revision)
        case .disabledForSession:
            availabilityState = .disabledForSession
            clearQueuedJobs()
        case .cooldown(let until):
            availabilityState = .cooldown(until: until)
            queuedJobs[job.revision] = job
            queuedRecipeRevisions.insert(job.revision, at: 0)
            scheduleCooldownResume(until: until)
        case .failed:
            failedRecipeRevisions.insert(job.revision)
        }
    }

    private func finishLoadingIfNeeded(for recipeID: PersistentIdentifier) {
        let hasQueuedRevision = queuedRecipeRevisions.contains { revision in
            revision.recipeID == recipeID
        }
        let hasQueuedJob = queuedJobs.keys.contains { revision in
            revision.recipeID == recipeID
        }
        let isProcessingCurrentRecipe = currentProcessingRevision?.recipeID == recipeID

        guard hasQueuedRevision == false,
              hasQueuedJob == false,
              isProcessingCurrentRecipe == false else {
            return
        }

        loadingRecipeIDs.remove(recipeID)
    }

    private func clearQueuedJobs() {
        queuedJobs.removeAll()
        queuedRecipeRevisions.removeAll()
        loadingRecipeIDs.removeAll()
        cooldownResumeTask?.cancel()
        cooldownResumeTask = nil
    }

    private func refreshAvailabilityStateIfNeeded() {
        guard case .cooldown(let until) = availabilityState else {
            return
        }
        guard until <= .now else {
            return
        }

        availabilityState = .enabled
        cooldownResumeTask?.cancel()
        cooldownResumeTask = nil
    }

    private func scheduleCooldownResume(until: Date) {
        cooldownResumeTask?.cancel()
        cooldownResumeTask = Task { [weak self] in
            let delay = max(0, until.timeIntervalSinceNow)
            try? await Task.sleep(
                nanoseconds: UInt64(delay * 1_000_000_000)
            )
            guard let self else {
                return
            }
            await MainActor.run {
                self.refreshAvailabilityStateIfNeeded()
                self.startQueueIfNeeded()
            }
        }
    }
}
