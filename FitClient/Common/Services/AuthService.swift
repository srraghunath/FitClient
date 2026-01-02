import Foundation
import Supabase

class AuthService {
    static let shared = AuthService()

        let supabase = SupabaseClient(
            supabaseURL: URL(string: "https://xhxyhexaoxnejrsusfhb.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoeHloZXhhb3huZWpyc3VzZmhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczMTIzMzcsImV4cCI6MjA4Mjg4ODMzN30.1v1t-y6wgcgzOTByyEcLT4_O8gw17sjlD5-wqHgJhL8"
        )

    private init() {}

    func signUp(email: String, password: String, fullName: String, age: String, gender: String, specialization: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                let metadata: [String: AnyJSON] = [
                    "full_name": .string(fullName),
                    "age": .string(age),
                    "gender": .string(gender),
                    "specialization": .string(specialization)
                ]

                let _ = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: metadata
                )
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                try await supabase.auth.signIn(email: email, password: password)
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

                let _ = try await supabase.auth.signUp(
                    email: email,
                    password: password,
                    data: metadata
                )
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
}
