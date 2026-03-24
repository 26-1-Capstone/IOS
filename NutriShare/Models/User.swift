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
    let dong: String?

    var cityOrDistrict: String? { addressLine1 }
    var districtDisplay: String? {
        let raw = addressLine1?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return nil }

        let tokens = raw.split(separator: " ").map(String.init)
        guard !tokens.isEmpty else { return nil }

        var collected: [String] = []
        for token in tokens {
            collected.append(token)
            if token.hasSuffix("구") || token.hasSuffix("군") {
                return collected.joined(separator: " ")
            }
        }

        if let cityToken = tokens.first(where: { $0.hasSuffix("시") }) {
            return cityToken
        }

        return tokens.first
    }

    var neighborhoodDisplay: String? {
        let city = districtDisplay?.trimmingCharacters(in: .whitespacesAndNewlines)
        let dong = self.dong?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (city?.isEmpty == false ? city : nil, dong?.isEmpty == false ? dong : nil) {
        case let (city?, dong?):
            return "\(city) \(dong)"
        case let (city?, nil):
            return city
        case let (nil, dong?):
            return dong
        default:
            return nil
        }
    }
}

struct ProfileUpdateRequest: Encodable {
    let nickname: String
    let zipCode: String?
    let addressLine1: String?
    let addressLine2: String?
    let dong: String?
}
