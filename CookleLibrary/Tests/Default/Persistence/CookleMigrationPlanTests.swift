@testable import CookleLibrary
import Foundation
import SwiftData
import Testing

/// Pins the invariants that make schema selection explicit rather than positional.
///
/// `ModelContainerFactory` opens every container with
/// `CookleMigrationPlan.currentSchema`, not with `schemas[0]`. That is only
/// meaningful while the plan's own history stays consistent: the moment a second
/// schema is added, an unordered list, a missing stage, or a `currentSchema` that
/// is not the newest entry would each send shipped installs down a migration
/// SwiftData cannot perform.
///
/// These checks are deliberately trivial today, with one schema and no stages.
/// They exist so that the day a V2 lands, the omission fails here.
struct CookleMigrationPlanTests {
    @Test
    func current_schema_is_the_newest_recorded_version() {
        #expect(Self.recordedVersions.contains(Self.currentVersion))
        #expect(Self.recordedVersions.max() == Self.currentVersion)
    }

    @Test
    func recorded_history_is_ordered_oldest_first_without_duplicates() {
        #expect(Self.recordedVersions == Self.recordedVersions.sorted())
        #expect(Set(Self.recordedVersions).count == Self.recordedVersions.count)
    }

    @Test
    func every_adjacent_pair_of_schemas_has_a_migration_stage() {
        // One stage per step in the history. A V2 added without a stage would
        // leave a shipped V1 store with no defined path forward.
        #expect(CookleMigrationPlan.stages.count == Self.recordedVersions.count - 1)
    }

    @Test
    func the_current_schema_is_the_released_one() {
        // `ModelContainerFactory` builds `Schema(versionedSchema:)` from
        // `currentSchema`; this pins that the resulting schema is the released
        // one rather than whatever happens to sit first in the array.
        let selected = Schema(versionedSchema: CookleMigrationPlan.currentSchema)
        let released = Schema(versionedSchema: CookleSchemaV1.self)
        #expect(selected.version == released.version)
        #expect(selected.entities.map(\.name).sorted() == released.entities.map(\.name).sorted())
    }
}

private extension CookleMigrationPlanTests {
    static var currentVersion: Schema.Version {
        CookleMigrationPlan.currentSchema.versionIdentifier
    }

    static var recordedVersions: [Schema.Version] {
        var versions = [Schema.Version]()
        for schema in CookleMigrationPlan.schemas {
            versions.append(schema.versionIdentifier)
        }
        return versions
    }
}
