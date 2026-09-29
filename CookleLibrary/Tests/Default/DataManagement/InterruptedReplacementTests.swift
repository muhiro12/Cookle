@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

// Two failure modes criterion 3 names that cannot be injected literally: a
// process killed mid-replacement, and a disk that fills during the write.
//
// Both are modelled by their observable shape rather than their cause. An
// interruption before the save is a replacement whose context is discarded without
// saving; a full disk is a save that throws a write error. What matters for
// this issue is the same in both cases — the store on disk must still hold the
// data it held before.
@MainActor
struct InterruptedReplacementTests {
    private typealias Support = CookleDataArchivePackageTestSupport

    enum WriteFailure: Error {
        case outOfSpace
    }

    @Test
    func a_replacement_abandoned_before_saving_leaves_the_store_intact() throws {
        try withDiskStore { url in
            let seeded = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: seeded
            )
            let before = try storeContent(at: url)

            // A separate context does the destructive work and is then dropped
            // without saving, the way a killed process would drop it.
            try autoreleasepool {
                let interrupted = try makeContext(at: url)
                _ = try CookleDataArchiveService.replaceAll(
                    with: Support.archive(
                        photoPayloads: [Data([Value.replacementPhotoByte])]
                    ),
                    context: interrupted,
                    calendar: Support.calendar
                ) { _ in
                    // The interruption: the save never happens.
                }
            }

            #expect(try storeContent(at: url) == before)
        }
    }

    @Test
    func a_save_that_runs_out_of_space_leaves_the_store_intact() throws {
        try withDiskStore { url in
            let seeded = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: seeded
            )
            let before = try storeContent(at: url)

            let context = try makeContext(at: url)
            #expect(throws: WriteFailure.self) {
                _ = try CookleDataArchiveService.replaceAll(
                    with: Support.archive(
                        photoPayloads: [Data([Value.replacementPhotoByte])]
                    ),
                    context: context,
                    calendar: Support.calendar
                ) { _ in
                    throw WriteFailure.outOfSpace
                }
            }

            // `replaceAll` rolls the context back before rethrowing, so the
            // abandoned deletions and inserts must not reach disk.
            #expect(context.hasChanges == false)
            #expect(try storeContent(at: url) == before)
        }
    }

    @Test
    func the_store_survives_repeated_interrupted_attempts() throws {
        try withDiskStore { url in
            let seeded = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(),
                context: seeded
            )
            let before = try storeContent(at: url)

            // A person retrying a failing replacement several times.
            for _ in 0..<Value.attemptCount {
                let context = try makeContext(at: url)
                #expect(throws: WriteFailure.self) {
                    _ = try CookleDataArchiveService.replaceAll(
                        with: Support.archive(
                            photoPayloads: [Data([Value.replacementPhotoByte])]
                        ),
                        context: context,
                        calendar: Support.calendar
                    ) { _ in
                        throw WriteFailure.outOfSpace
                    }
                }
            }

            #expect(try storeContent(at: url) == before)

            // And a successful replacement still works afterwards, so the failures
            // left nothing wedged.
            let recovering = try makeContext(at: url)
            _ = try DataMaintenanceOperations.replaceAllData(
                with: Support.archive(
                    photoPayloads: [Data([Value.replacementPhotoByte])]
                ),
                context: recovering
            )
            #expect(try storeContent(at: url) != before)
        }
    }
}

private extension InterruptedReplacementTests {
    enum Value {
        static let replacementPhotoByte: UInt8 = 99
        static let attemptCount = 3
    }

    func withDiskStore(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        try body(directory.appendingPathComponent("store.sqlite"))
    }

    func makeContext(at url: URL) throws -> ModelContext {
        let container = try ModelContainerFactory.makeModelContainer(
            url: url,
            cloudKitDatabase: .none
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    func storeContent(at url: URL) throws -> Data {
        try TestArchiveContent.data(
            storedIn: makeContext(at: url)
        )
    }
}
