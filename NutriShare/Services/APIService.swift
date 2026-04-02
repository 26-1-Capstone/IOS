import Foundation

/// Central API client for all network requests
class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let enableNetworkLogging = true
    let baseURL: String

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.httpCookieStorage = .shared
        config.httpShouldSetCookies = true
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.baseURL = Self.resolveBaseURL()
        log("API base URL: \(baseURL)")
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = AuthManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            request.httpBody = try encoder.encode(AnyEncodable(body))
            
            log("📤 Request to \(method) \(path)")
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        log("📡 Response [\(httpResponse.statusCode)] for \(method) \(path)")
        logResponsePreview(data, response: httpResponse, url: url)

        if httpResponse.statusCode == 401 {
            // Token expired — try refresh
            if let newToken = try? await refreshToken() {
                AuthManager.shared.setToken(newToken)
                request.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                let (retryData, retryResponse) = try await session.data(for: request)
                guard let retryHttp = retryResponse as? HTTPURLResponse,
                      (200...299).contains(retryHttp.statusCode) else {
                    AuthManager.shared.removeToken()
                    throw APIError.unauthorized(message: decodeUnauthorizedMessage(from: retryData))
                }
                return try decodeResponse(T.self, from: retryData, response: retryHttp, url: url)
            } else {
                AuthManager.shared.removeToken()
                throw APIError.unauthorized(message: decodeUnauthorizedMessage(from: data))
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = decodeServerMessage(from: data)
            log("❌ Server Error [\(httpResponse.statusCode)]: \(message)")
            throw APIError.serverError(httpResponse.statusCode, message: message)
        }

        return try decodeResponse(T.self, from: data, response: httpResponse, url: url)
    }

    private func refreshToken() async throws -> String? {
        guard let url = URL(string: authBaseURL + "/api/v1/auth/reissue") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return nil
        }

        let apiResponse = try decoder.decode(ApiResponse<String>.self, from: data)
        return apiResponse.data
    }

    private var authBaseURL: String {
        if baseURL.hasSuffix("/api/v1") {
            return String(baseURL.dropLast("/api/v1".count))
        }
        return baseURL
    }

    // MARK: - Convenience Methods

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil, authenticated: Bool = true) async throws -> T {
        try await request("GET", path: path, queryItems: queryItems, authenticated: authenticated)
    }

    func post<T: Decodable>(_ path: String, body: (any Encodable)? = nil, authenticated: Bool = true) async throws -> T {
        try await request("POST", path: path, body: body, authenticated: authenticated)
    }

    func put<T: Decodable>(_ path: String, body: (any Encodable)? = nil, authenticated: Bool = true) async throws -> T {
        try await request("PUT", path: path, body: body, authenticated: authenticated)
    }

    func delete<T: Decodable>(_ path: String, authenticated: Bool = true) async throws -> T {
        try await request("DELETE", path: path, authenticated: authenticated)
    }

    private func log(_ message: String) {
        #if DEBUG
        guard enableNetworkLogging else { return }
        print(message)
        #endif
    }

    private func decodeResponse<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        response: HTTPURLResponse,
        url: URL
    ) throws -> T {
        if let preview = responsePreview(data), preview.hasPrefix("<") {
            // Spring Security might redirect to a login page if the token is invalid/missing instead of returning 401.
            if preview.contains("login") || preview.contains("<!DOCTYPE html>") {
                AuthManager.shared.removeToken()
                throw APIError.unauthorized(message: "로그인이 만료되었어요. 다시 로그인해 주세요.")
            }
            
            throw APIError.nonJSONResponse(
                statusCode: response.statusCode,
                url: url.absoluteString,
                preview: preview
            )
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(
                url: url.absoluteString,
                statusCode: response.statusCode,
                underlying: error.localizedDescription,
                preview: responsePreview(data)
            )
        }
    }

    private func logResponsePreview(_ data: Data, response: HTTPURLResponse, url: URL) {
        guard enableNetworkLogging, let preview = responsePreview(data) else { return }
        print("📄 Response preview [\(response.statusCode)] \(url.absoluteString): \(preview)")
    }

    private func responsePreview(_ data: Data) -> String? {
        guard !data.isEmpty else { return nil }
        let previewData = data.prefix(200)
        return String(data: previewData, encoding: .utf8)?
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func decodeServerMessage(from data: Data) -> String {
        if let payload = try? decoder.decode(ApiResponse<EmptyResponse>.self, from: data),
           let message = payload.error?.message?.nilIfBlank {
            return message
        }

        if let payload = try? decoder.decode(ApiError.self, from: data),
           let message = payload.message?.nilIfBlank {
            return message
        }

        return "요청 처리에 실패했습니다."
    }

    private func decodeUnauthorizedMessage(from data: Data) -> String {
        let message = decodeServerMessage(from: data)
        if message == "요청 처리에 실패했습니다." {
            return "로그인이 만료되었어요. 다시 로그인해 주세요."
        }
        return message
    }

    private static func resolveBaseURL() -> String {
        if let override = UserDefaults.standard.string(forKey: "APIBaseURLOverride")?.nilIfBlank {
            return override.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        if let configured = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
           !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return configured.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        return "http://localhost:8080/api/v1"
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized(message: String)
    case serverError(Int, message: String)
    case nonJSONResponse(statusCode: Int, url: String, preview: String)
    case decodingFailed(url: String, statusCode: Int, underlying: String, preview: String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다."
        case .invalidResponse: return "서버 응답이 올바르지 않습니다."
        case .unauthorized(let message): return message
        case .serverError(let code, let message): return "\(message) (\(code))"
        case .nonJSONResponse(let statusCode, let url, let preview):
            return "JSON 대신 다른 응답을 받았습니다. [\(statusCode)] \(url) \(preview)"
        case .decodingFailed(let url, let statusCode, let underlying, let preview):
            if let preview, !preview.isEmpty {
                return "응답 디코딩에 실패했습니다. [\(statusCode)] \(url) \(underlying) \(preview)"
            }
            return "응답 디코딩에 실패했습니다. [\(statusCode)] \(url) \(underlying)"
        }
    }
}

// MARK: - Type-erased Encodable wrapper

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

private struct EmptyResponse: Decodable {}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
