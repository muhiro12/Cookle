import Testing

@testable import Cookle

@MainActor
struct FormSnapshotRestorePolicyTests {
    @Test
    func restore_isAvailableOnlyWhenSnapshotExists() {
        let missingSnapshotPolicy = FormSnapshotRestorePolicy(
            hasSnapshot: false,
            isCurrentInputNearlyEmpty: true
        )
        let existingSnapshotPolicy = FormSnapshotRestorePolicy(
            hasSnapshot: true,
            isCurrentInputNearlyEmpty: true
        )

        #expect(missingSnapshotPolicy.isRestoreAvailable == false)
        #expect(existingSnapshotPolicy.isRestoreAvailable)
    }

    @Test
    func restore_requiresConfirmationOnlyWhenCurrentInputIsNotNearlyEmpty() {
        let emptyInputPolicy = FormSnapshotRestorePolicy(
            hasSnapshot: true,
            isCurrentInputNearlyEmpty: true
        )
        let populatedInputPolicy = FormSnapshotRestorePolicy(
            hasSnapshot: true,
            isCurrentInputNearlyEmpty: false
        )

        #expect(emptyInputPolicy.requiresOverwriteConfirmation == false)
        #expect(populatedInputPolicy.requiresOverwriteConfirmation)
    }
}
