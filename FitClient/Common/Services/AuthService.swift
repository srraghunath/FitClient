import Foundation
import Supabase
import Security

enum UserRole {
    case trainer(userId: UUID)
    case client(userId: UUID, clientId: UUID, trainerId: UUID?)
}

class AuthService {
    static let shared = AuthService()

        let supabase = SupabaseClient(
            supabaseURL: URL(string: "https://xhxyhexaoxnejrsusfhb.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoeHloZXhhb3huZWpyc3VzZmhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczMTIzMzcsImV4cCI6MjA4Mjg4ODMzN30.1v1t-y6wgcgzOTByyEcLT4_O8gw17sjlD5-wqHgJhL8"
        )

    private let refreshTokenKey = "fitbond.supabase.refresh_token"
    private let accessTokenKey = "fitbond.supabase.access_token"
    private(set) var cachedRole: UserRole?

    private init() {}

    func signUp(email: String, password: String, fullName: String, age: String, gender: String, specialization: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                let metadata: [String: AnyJSON] = [
                    "full_name": .string(fullName),
                    "age": .string(age),
                    "gender": .string(gender),
                    "specialization": .string(specialization),
                    "user_type": .string("trainer")
                ]

                let authResponse: AuthResponse = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: metadata
                )
                if let session = authResponse.session {
                    storeSessionTokens(session)
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                let session: Supabase.Session = try await supabase.auth.signIn(email: email, password: password)
                storeSessionTokens(session)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func forgotPassword(email: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await supabase.auth.resetPasswordForEmail(email)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func signUpClient(email: String, password: String, fullName: String, age: String, gender: String, goal: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                let metadata: [String: AnyJSON] = [
                    "full_name": .string(fullName),
                    "age": .string(age),
                    "gender": .string(gender),
                    "goal": .string(goal),
                    "user_type": .string("client")
                ]

                let authResponse: AuthResponse = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: metadata
                )
                if let session = authResponse.session {
                    storeSessionTokens(session)
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    // MARK: - Session Persistence

    func restoreSession() async throws -> UserRole {
        if let refresh = loadToken(forKey: refreshTokenKey) {
            do {
                let session: Supabase.Session = try await supabase.auth.refreshSession(refreshToken: refresh)
                storeSessionTokens(session)
            } catch {
                clearStoredTokens()
                throw error
            }
        }

        guard let role = try await resolveCurrentRole() else {
            throw NSError(domain: "AuthService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User role not found"])
        }
        cachedRole = role
        return role
    }

    func signOut(completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await supabase.auth.signOut()
                clearStoredTokens()
                cachedRole = nil
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    // MARK: - Role Resolution

    func resolveCurrentRole() async throws -> UserRole? {
        guard let userId = supabase.auth.currentUser?.id else { return nil }

        // Check trainer table first
        let trainerRows: [TrainerRow] = try await supabase
            .from("trainers")
            .select()
            .eq("id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if trainerRows.first != nil {
            return .trainer(userId: userId)
        }

        // Then check clients by user_id
        let clientRows: [ClientRow] = try await supabase
            .from("clients")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        if let client = clientRows.first {
            return .client(userId: userId, clientId: client.id, trainerId: client.trainerId)
        }

        return nil
    }

    // MARK: - Keychain

    private func storeSessionTokens(_ session: Supabase.Session) {
        storeToken(session.refreshToken, forKey: refreshTokenKey)
        storeToken(session.accessToken, forKey: accessTokenKey)
    }

    private func clearStoredTokens() {
        deleteToken(forKey: refreshTokenKey)
        deleteToken(forKey: accessTokenKey)
    }

    private func storeToken(_ token: String, forKey key: String) {
        let tokenData = token.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: tokenData
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadToken(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func deleteToken(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
