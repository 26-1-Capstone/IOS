import Foundation

struct CartData: Codable {
    let cartId: Int?
    let items: [CartItem]
    let totalAmount: Int
}

struct CartItem: Codable, Identifiable {
    let productId: Int
    let productName: String
    let typePrice: Int
    let quantity: Int
    let totalPrice: Int
    let imageUrl: String?

    var id: Int { productId }
}
