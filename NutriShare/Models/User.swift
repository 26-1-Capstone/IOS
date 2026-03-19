import Foundation

struct UserProfile: Codable {
    let userId: Int?
    let email: String?
    let nickname: String?
    let address: UserAddress?
    let profileImageUrl: String?
    let totalSavings: Int?
}

struct UserAddress: Codable {
    let zipCode: String?
    let addressLine1: String?
    let addressLine2: String?
}

struct ProfileUpdateRequest: Encodable {
    let nickname: String
    let zipCode: String?
    let addressLine1: String?
    let addressLine2: String?
}
