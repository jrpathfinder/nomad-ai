import StoreKit
import SwiftUI

@MainActor
final class SubscriptionManager: ObservableObject {
    static let productIDs = [
        "nomadinventory.premium.monthly",
        "nomadinventory.premium.annual"
    ]

    @Published private(set) var isPremium = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPurchasing = false
    @Published var errorMessage: String?

    init() {
        Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
                await self?.refreshStatus()
            }
        }
        Task {
            await loadProducts()
            await refreshStatus()
        }
    }

    var annual: Product? { products.first { $0.subscription?.subscriptionPeriod.unit == .year } }

    func loadProducts() async {
        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshStatus()
            case .success(.unverified(_, let error)):
                errorMessage = error.localizedDescription
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
        } catch {
            errorMessage = error.localizedDescription
        }
        await refreshStatus()
    }

    func refreshStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               Self.productIDs.contains(t.productID),
               t.revocationDate == nil {
                active = true
            }
        }
        isPremium = active
    }
}
