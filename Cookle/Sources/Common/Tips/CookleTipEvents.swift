import TipKit

enum CookleTipEvents {
    nonisolated static let didOpenRecipeDetail = Tips.Event(id: "did-open-recipe-detail")
    nonisolated static let didOpenDiaryForm = Tips.Event(id: "did-open-diary-form")
    nonisolated static let didOpenSubscription = Tips.Event(id: "did-open-subscription")
}
