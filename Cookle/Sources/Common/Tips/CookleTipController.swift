import TipKit

@MainActor
@Observable
final class CookleTipController {
    private(set) var isConfigured = false

    func configureIfNeeded() throws {
        guard isConfigured == false else {
            return
        }

        try Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
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
