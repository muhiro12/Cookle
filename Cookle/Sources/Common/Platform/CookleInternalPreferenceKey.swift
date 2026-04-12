import MHPlatform

enum CookleInternalPreferenceKey: String, CaseIterable, Sendable {
    case preferenceLifecycleState = "N3dR7vXc"

    var migrationStateDescriptor: MHPreferenceMigrationStateDescriptor {
        .init(
            storageKey: rawValue,
            defaultSelection: .standard
        )
    }
}
