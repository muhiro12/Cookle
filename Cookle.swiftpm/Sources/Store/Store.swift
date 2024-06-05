//
//  Store.swift
//
//
//  Created by Hiromu Nakano on 2024/06/05.
//

import StoreKit

@Observable
final class Store {
    private(set) var groupID: String
    private(set) var productIDs: [String]
    private(set) var product: Product?

    private var updateListenerTask: Task<Void, Error>?

    private var subscriptions: [Product] {
        didSet {
            product = subscriptions.first { productIDs.contains($0.id) }
        }
    }

    private var purchasedSubscriptions: [Product] {
        didSet {
            UserDefaults.standard.set(
                purchasedSubscriptions.contains { productIDs.contains($0.id) },
                forKey: AppStorageKey.isSubscribeOn.rawValue
            )
        }
    }

    init() {
        groupID = ""
        productIDs = []
        product = nil
        updateListenerTask = nil
        subscriptions = []
        purchasedSubscriptions = []
    }

    func open(groupID: String, productIDs: [String]) {
        self.groupID = groupID
        self.productIDs = productIDs

        updateListenerTask = listenForTransactions()

        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    await self.updateCustomerProductStatus()

                    await transaction.finish()
                } catch {
                    assertionFailure("Transaction failed verification: \(error.localizedDescription)")
                }
            }
        }
    }

    private func requestProducts() async {
        do {
            subscriptions = try await Product.products(for: productIDs)
        } catch {
            assertionFailure("Failed product request from the App Store server: \(error)")
        }
    }

    private func updateCustomerProductStatus() async {
        var purchasedSubscriptions: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }

                default:
                    break
                }
            } catch {
                assertionFailure("Transaction failed verification: \(error.localizedDescription)")
            }
        }

        self.purchasedSubscriptions = purchasedSubscriptions
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError() // TODO: Handle Error

        case .verified(let safe):
            return safe
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }
}
