import Foundation

class AuthService {
    static let shared = AuthService()
    private let baseURL = URL(string: "http://localhost:3000/api/auth")!
    private let tokenKey = "authToken"

    private init() {}

    var isAuthenticated: Bool {
        return UserDefaults.standard.string(forKey: tokenKey) != nil
    }

    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }

    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        // Post a notification to trigger navigation to the login screen
        NotificationCenter.default.post(name: .didLogout, object: nil)
    }

    func signup(email: String, password: String, fullName: String, role: String, specialization: String? = nil, goals: String? = nil, completion: @escaping (Bool, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("signup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "email": email,
            "password": password,
            "fullName": fullName,
            "role": role
        ]

        if let specialization = specialization {
            body["specialization"] = specialization
        }
        if let goals = goals {
            body["goals"] = goals
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, error) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let err = NSError(domain: "AuthService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Signup failed. Please check the details and try again."])
                DispatchQueue.main.async { completion(false, err) }
                return
            }

            DispatchQueue.main.async { completion(true, nil) }
        }.resume()
    }

    func login(email: String, password: String, completion: @escaping (Bool, Error?) -> Void) {
        let url = baseURL.appendingPathComponent("login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(false, error) }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let err = NSError(domain: "AuthService", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Login failed. Please check your credentials."])
                DispatchQueue.main.async { completion(false, err) }
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let token = json["accessToken"] as? String {
                    self?.saveToken(token)
                    DispatchQueue.main.async { completion(true, nil) }
                } else {
                    let err = NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid token format received from server."])
                    DispatchQueue.main.async { completion(false, err) }
                }
            } catch {
                DispatchQueue.main.async { completion(false, error) }
            }
        }.resume()
    }
}

extension Notification.Name {
    static let didLogout = Notification.Name("didLogout")
}
