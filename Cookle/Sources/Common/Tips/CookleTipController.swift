import TipKit

@MainActor
@Observable
final class CookleTipController {
    private static let currentTipExperienceVersion = 1

    private(set) var isConfigured = false

    func configureIfNeeded() throws {
        guard isConfigured == false else {
            return
        }

        let didMigrateTipExperience = try migrateTipExperienceIfNeeded()
        try Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])

        if didMigrateTipExperience {
            CooklePreferences.set(
                Self.currentTipExperienceVersion,
                for: .tipExperienceVersion
            )
        }
        isConfigured = true
    }

    func donateDidOpenRecipeDetail() {
        CookleTipEvents.didOpenRecipeDetail.sendDonation()
    }

    func donateDidOpenDiaryForm() {
        CookleTipEvents.didOpenDiaryForm.sendDonation()
    }

    func donateDidOpenSubscription() {
        CookleTipEvents.didOpenSubscription.sendDonation()
    }

    func resetTips() throws {
        try Tips.resetDatastore()
    }
}

private extension CookleTipController {
    func migrateTipExperienceIfNeeded() throws -> Bool {
        let storedVersion = CooklePreferences.int(
            for: .tipExperienceVersion,
            default: .zero
        )
        guard storedVersion < Self.currentTipExperienceVersion else {
            return false
        }

        try Tips.resetDatastore()
        return true
    }
}
