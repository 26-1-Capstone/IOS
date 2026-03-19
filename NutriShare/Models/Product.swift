import Foundation

struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let price: Int
    let categoryName: String?
    let description: String?
    let stockQuantity: Int?
    let categoryId: Int?
    let imageUrl: String?
}
