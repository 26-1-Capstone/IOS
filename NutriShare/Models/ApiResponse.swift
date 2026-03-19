import Foundation

/// Standard API response wrapper matching backend format
struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: ApiError?
}

struct ApiError: Decodable {
    let code: String?
    let message: String?
}

/// Paginated response data
struct PagedData<T: Decodable>: Decodable {
    let content: [T]
    let totalElements: Int?
    let totalPages: Int?
    let last: Bool?
}
