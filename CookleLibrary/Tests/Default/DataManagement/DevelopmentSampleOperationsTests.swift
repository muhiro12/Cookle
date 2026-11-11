#if DEBUG
@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

@MainActor
struct DevelopmentSampleOperationsTests: MutationRollbackTestSupport {
    private enum FixtureError: Error {
        case interrupted
    }

    @Test
    func sampleInsertionCommitsOnceAndRejectsDuplicatesAfterReopen() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            try DevelopmentSampleOperations.insert(context: context, storeURL: url) { context in
                _ = makeRecipe(context: context, name: "Sample")
            }
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Sample"])
            #expect(throws: DevelopmentSampleOperations.SampleError.nonemptyStore) {
                try DevelopmentSampleOperations.insert(context: reopened, storeURL: url) { _ in
                    Issue.record("A nonempty store must never invoke the fixture builder.")
                }
            }
        }
    }

    @Test
    func refusesOtherStoreAndPreservesPendingEdits() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            #expect(throws: DevelopmentSampleOperations.SampleError.unsafeStore) {
                try DevelopmentSampleOperations.insert(
                    context: context, storeURL: url.appendingPathExtension("other")
                ) { _ in
                    Issue.record("The wrong store must never invoke the fixture builder.")
                }
            }
            let recipe = makeRecipe(context: context, name: "Unsaved")
            #expect(throws: DevelopmentSampleOperations.SampleError.pendingChanges) {
                try DevelopmentSampleOperations.insert(context: context, storeURL: url) { _ in
                    Issue.record("Pending edits must never reach the fixture builder.")
                }
            }
            #expect(recipe.name == "Unsaved")
            #expect(context.hasChanges)
            #expect(try DiagnosticRecordCounts.read(container: context.container).isEmpty)
            #expect(context.hasChanges)
        }
    }

    @Test
    func fixtureFailureRollsBackAndAllowsManualRetry() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            #expect(throws: FixtureError.interrupted) {
                try DevelopmentSampleOperations.insert(context: context, storeURL: url) { context in
                    _ = makeRecipe(context: context, name: "Discard")
                    throw FixtureError.interrupted
                }
            }
            #expect(!context.hasChanges)
            #expect(try DiagnosticRecordCounts.read(container: context.container).isEmpty)
            #expect(!context.autosaveEnabled)
            try DevelopmentSampleOperations.insert(context: context, storeURL: url) { context in
                _ = makeRecipe(context: context, name: "Retry")
            }
            let reopened = try makeContext(at: url)
            #expect(try reopened.fetch(.recipes(.all)).map(\.name) == ["Retry"])
        }
    }

    @Test
    func detachedStructuralRecordsPreventSampleInsertion() throws {
        try withDiskStore { url in
            let context = try makeContext(at: url)
            _ = try IngredientObject.create(context: context, ingredient: "Salt", amount: "1 tsp", order: 1)
            try context.save()
            let counts = try DiagnosticRecordCounts.read(container: context.container)
            #expect(counts.recipes == 0)
            #expect(counts.ingredientObjects == 1)
            #expect(!counts.isEmpty)
            #expect(throws: DevelopmentSampleOperations.SampleError.nonemptyStore) {
                try DevelopmentSampleOperations.insert(context: context, storeURL: url) { _ in
                    Issue.record("Detached rows must be preserved.")
                }
            }
        }
    }

    @Test
    func refusesCloudReadOnlyMemoryAndSharedConfigurations() {
        let url = URL.temporaryDirectory.appending(path: "CookleDevelopmentPolicy.store")
        let configurations: [ModelConfiguration] = [
            .init(url: url, cloudKitDatabase: .private("iCloud.example.development")),
            .init(url: url, allowsSave: false, cloudKitDatabase: .none),
            .init(isStoredInMemoryOnly: true, groupContainer: .none, cloudKitDatabase: .none),
            .init(url: Database.url, cloudKitDatabase: .none),
            .init(url: Database.legacyURL, cloudKitDatabase: .none)
        ]
        for configuration in configurations {
            #expect(!DevelopmentSampleOperations.allowsMutations(configurations: [configuration], storeURL: url))
        }
        #expect(!DevelopmentSampleOperations.allowsMutations(configurations: [], storeURL: url))
        #expect(!DevelopmentSampleOperations.allowsMutations(
            configurations: [.init(url: url, cloudKitDatabase: .none), .init(url: url, cloudKitDatabase: .none)],
            storeURL: url
        ))
        #expect(!DevelopmentSampleOperations.allowsMutations(
            configurations: [.init(url: Database.url, cloudKitDatabase: .none)], storeURL: Database.url
        ))
    }
}
#endif
