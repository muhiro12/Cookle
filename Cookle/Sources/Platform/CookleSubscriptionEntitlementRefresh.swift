import StoreKit

@MainActor
final class CookleSubscriptionEntitlementRefresh {
    var report: (@MainActor (Set<String>) -> Void)?

    func refresh() async {
        let productID = CookleMonetizationConfiguration.subscriptionProductID
        var identifiers: Set<String> = []
        // StoreKit views can see a new plan before the transaction listener
        // reports it. Re-read the same verified entitlement authority on a
        // subscription status change, including purchases and restores.
        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                if transaction.productID == productID {
                    identifiers.insert(productID)
                }
            case .unverified:
                return
            }
        }

        if !Task.isCancelled {
            report?(identifiers)
        }
    }
}
