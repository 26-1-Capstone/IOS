import Foundation

struct GroupPurchase: Codable, Identifiable {
    let id: Int
    let title: String
    let productName: String?
    let imageUrl: String?
    let typePrice: Int?
    let targetQuantity: Int
    let currentQuantity: Int
    let dueDate: String?
    let endAt: String?
    let description: String?
    let productId: Int?
    let status: String?
}

struct GroupCreateRequest: Encodable {
    let productId: Int
    let title: String
    let description: String?
    let targetQuantity: Int
    let unitPrice: Int
    let endAt: String
}

struct Participation: Codable, Identifiable {
    let participationId: Int
    let groupPurchaseId: Int?
    let groupId: Int?
    let title: String?
    let productName: String?
    let quantity: Int?
    let status: String?
    let createdAt: String?
    let currentQuantity: Int?
    let targetQuantity: Int?

    var id: Int { participationId }
}
