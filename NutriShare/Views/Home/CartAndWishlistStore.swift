import Foundation
import SwiftUI

struct StoreProduct: Identifiable {
    let id: Int
}

final class CartStore: ObservableObject {
    @Published private(set) var productIds: [Int] = []

    init() {
        Task {
            await load()
        }
    }

    @MainActor
    func load() async {
        do {
            let response: ApiResponse<CartData> = try await APIService.shared.get("/cart")
            if let items = response.data?.items {
                self.productIds = items.map { $0.productId }
            }
        } catch {
            print("Failed to load CartStore: \(error)")
        }
    }

    func add(_ product: StoreProduct) {
        // Optimistic UI update
        if !productIds.contains(product.id) {
            productIds.append(product.id)
        }
        
        struct AddRequest: Encodable {
            let productId: Int
            let quantity: Int
        }
        
        Task {
            do {
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.post(
                    "/cart",
                    body: AddRequest(productId: product.id, quantity: 1)
                )
                await load() // refresh state from server
            } catch {
                print("Failed to add to cart on server: \(error)")
            }
        }
    }

    func remove(_ product: StoreProduct) {
        productIds.removeAll { $0 == product.id }
        
        Task {
            do {
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.delete("/cart/\(product.id)")
                await load()
            } catch {
                print("Failed to remove from cart on server: \(error)")
            }
        }
    }

    func contains(_ product: StoreProduct) -> Bool {
        productIds.contains(product.id)
    }
}

final class WishlistStore: ObservableObject {
    @Published private(set) var productIds: Set<Int> = []

    func toggle(_ product: StoreProduct) {
        if productIds.contains(product.id) {
            productIds.remove(product.id)
        } else {
            productIds.insert(product.id)
        }
    }

    func contains(_ product: StoreProduct) -> Bool {
        productIds.contains(product.id)
    }
}
