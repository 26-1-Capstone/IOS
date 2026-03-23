import Foundation
import Combine
import Security

/// Manages JWT token storage and authentication state
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    private let tokenKey = "nutrishare_access_token"
    private let service = "com.nutrishare.ios"

    @Published var isAuthenticated: Bool = false

    private init() {
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            removeToken()
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        migrateTokenIfNeeded()
        self.isAuthenticated = getToken() != nil
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        guard isJwtLike(token) else {
            removeToken()
            return nil
        }
        return token
    }

    func setToken(_ token: String) {
        guard isJwtLike(token) else {
            removeToken()
            return
        }

        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var createQuery = query
            createQuery[kSecValueData as String] = data
            SecItemAdd(createQuery as CFDictionary, nil)
        }

        DispatchQueue.main.async {
            self.isAuthenticated = true
        }
    }

    private func isJwtLike(_ token: String) -> Bool {
        token.split(separator: ".").count == 3
    }

    func removeToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)

        DispatchQueue.main.async {
            self.isAuthenticated = false
        }
    }

    private func migrateTokenIfNeeded() {
        guard let legacyToken = UserDefaults.standard.string(forKey: tokenKey),
              getToken() == nil else {
            return
        }
        setToken(legacyToken)
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
