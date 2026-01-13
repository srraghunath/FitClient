import Foundation
import UIKit
import Supabase

struct ClientProfileRecord: Codable {
    let id: UUID
    let userId: UUID?
    let trainerId: UUID?
    let fullName: String?
    let age: Int?
    let gender: String?
    let goal: String?
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case trainerId = "trainer_id"
        case fullName = "full_name"
        case age
        case gender
        case goal
        case profileImageURL = "profile_image_url"
    }
}

struct ClientProfileUpdatePayload: Encodable {
    let full_name: String
    let age: Int
    let gender: String
    let goal: String
    let profile_image_url: String?
}

private struct UpdateClientProfileParams: Encodable {
    let _full_name: String
    let _age: Int
    let _gender: String
    let _goal: String
    let _profile_image_url: String?
}

final class ClientProfileService {

    static let shared = ClientProfileService()
    private let supabase = AuthService.shared.supabase

    private init() {}

    // MARK: - Fetch
    func fetchProfile(completion: @escaping (Result<ClientProfileRecord, Error>) -> Void) {
        Task {
            do {
                print("[ClientProfileService] Calling RPC get_client_profile")
                let profiles: [ClientProfileRecord] = try await supabase
                    .rpc("get_client_profile")
                    .execute()
                    .value

                guard let profile = profiles.first else {
                    completion(.failure(NSError(
                        domain: "ClientProfileService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Client profile not found"]
                    )))
                    return
                }

                completion(.success(profile))
            } catch {
                print("[ClientProfileService] fetchProfile failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Update
    func updateProfile(
        _ update: ClientProfileUpdatePayload,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                print("[ClientProfileService] Updating client profile via RPC update_client_profile")
                let params = UpdateClientProfileParams(
                    _full_name: update.full_name,
                    _age: update.age,
                    _gender: update.gender,
                    _goal: update.goal,
                    _profile_image_url: update.profile_image_url
                )

                try await supabase
                    .rpc("update_client_profile", params: params)
                    .execute()

                completion(nil)
            } catch {
                print("[ClientProfileService] updateProfile failed: \(error)")
                completion(error)
            }
        }
    }

    // MARK: - Upload
    func uploadProfileImage(
        _ image: UIImage,
        for userId: UUID,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let currentUserId = supabase.auth.currentUser?.id else {
            completion(.failure(NSError(
                domain: "ClientProfileService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated; cannot upload profile image"]
            )))
            return
        }

        if currentUserId != userId {
            print("[ClientProfileService] Warning: current auth user (\(currentUserId)) does not match requested userId (\(userId)).")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(
                domain: "ClientProfileService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]
            )))
            return
        }

        let userIdString = userId.uuidString.lowercased()
        let filePath = "\(userIdString)/\(userIdString).jpg"

        Task {
            do {
                print("[ClientProfileService] Uploading image to profile-images at path=\(filePath)")
                try await supabase.storage
                    .from("profile-images")
                    .upload(
                        filePath,
                        data: imageData,
                        options: FileOptions(cacheControl: "3600", upsert: true)
                    )

                let publicURL = try supabase.storage
                    .from("profile-images")
                    .getPublicURL(path: filePath)

                print("[ClientProfileService] Upload succeeded. Public URL=\(publicURL.absoluteString)")
                completion(.success(publicURL.absoluteString))
            } catch {
                print("[ClientProfileService] uploadProfileImage failed: \(error)")
                completion(.failure(error))
            }
        }
    }
}
