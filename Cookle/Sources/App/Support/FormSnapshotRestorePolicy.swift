struct FormSnapshotRestorePolicy: Equatable {
    let hasSnapshot: Bool
    let isCurrentInputNearlyEmpty: Bool

    var isRestoreAvailable: Bool {
        hasSnapshot
    }

    var requiresOverwriteConfirmation: Bool {
        hasSnapshot && isCurrentInputNearlyEmpty == false
    }
}
