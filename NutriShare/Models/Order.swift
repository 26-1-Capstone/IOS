import Foundation

struct OrderSummary: Codable, Identifiable {
    let orderId: Int
    let status: String?
    let totalAmount: Int
    let createdAt: String?
    let orderDate: String?
    let summary: String?

    var id: Int { orderId }
}

struct OrderCreateRequest: Encodable {
    let shippingAddress: ShippingAddress
    let items: [OrderItemRequest]
}

struct ShippingAddress: Codable {
    let zipCode: String
    let line1: String
    let line2: String
}

struct OrderItemRequest: Encodable {
    let productId: Int
    let productName: String
    let unitPrice: Int
    let quantity: Int
}

struct ResourceResponse: Codable {
    let resourceId: Int?
    let status: String?
}
