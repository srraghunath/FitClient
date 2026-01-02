import Foundation
import UIKit
import Supabase

// MARK: - Models

struct TrainerProfile: Codable {
    let fullName: String
    let age: Int?
    let gender: String?
    let specialization: String?
    let profileImageURL: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case age
        case gender
        case specialization
        case profileImageURL = "profile_image_url"
    }
}

struct TrainerProfileUpdate: Encodable {
    let full_name: String
    let age: Int?
    let gender: String?
    let specialization: String?
    let profile_image_url: String?
}

// MARK: - Service

final class TrainerService {

    static let shared = TrainerService()
    private let supabase = AuthService.shared.supabase

    private init() {}

    // MARK: - Fetch Profile (RPC)

    func fetchTrainerProfile(
        completion: @escaping (Result<TrainerProfile, Error>) -> Void
    ) {
        Task {
            do {
                print("[TrainerService] Calling RPC get_trainer_profile")
                let profiles: [TrainerProfile] = try await supabase
                    .rpc("get_trainer_profile")
                    .execute()
                    .value

                guard let profile = profiles.first else {
                    print("[TrainerService] No profile rows returned")
                    completion(.failure(NSError(
                        domain: "TrainerService",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "Trainer profile not found"]
                    )))
                    return
                }

                print("[TrainerService] Profile loaded: name=\(profile.fullName) image=\(profile.profileImageURL ?? "nil")")
                completion(.success(profile))
            } catch {
                print("[TrainerService] fetchTrainerProfile failed: \(error)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Update Profile

    func updateTrainerProfile(
        _ update: TrainerProfileUpdate,
        for userId: UUID,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                print("[TrainerService] Updating trainer profile for id=\(userId)")
                try await supabase
                    .from("trainers")
                    .update(update)
                    .eq("id", value: userId.uuidString)
                    .execute()

                print("[TrainerService] Update succeeded")
                completion(nil)
            } catch {
                print("[TrainerService] updateTrainerProfile failed: \(error)")
                completion(error)
            }
        }
    }

    // MARK: - Upload Profile Image

    func uploadProfileImage(
        _ image: UIImage,
        for userId: UUID,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let currentUserId = supabase.auth.currentUser?.id else {
            let error = NSError(
                domain: "TrainerService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Not authenticated; cannot upload profile image"]
            )
            print("[TrainerService] uploadProfileImage aborted: no auth user")
            completion(.failure(error))
            return
        }

        if currentUserId != userId {
            print("[TrainerService] Warning: current auth user (\(currentUserId)) does not match requested userId (\(userId)). Proceeding may fail RLS.")
        }

        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(
                domain: "TrainerService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]
            )))
            return
        }

        let userIdString = userId.uuidString.lowercased()
        let filePath = "\(userIdString)/\(userIdString).jpg"

        Task {
            do {
                print("[TrainerService] Uploading image to profile-images at path=\(filePath)")
                try await supabase.storage
                    .from("profile-images")
                    .upload(
                        filePath,
                        data: imageData,
                        options: FileOptions(
                            cacheControl: "3600",
                            upsert: true
                        )
                    )

                let publicURL = try supabase.storage
                    .from("profile-images")
                    .getPublicURL(path: filePath)

                print("[TrainerService] Upload succeeded. Public URL=\(publicURL.absoluteString)")
                completion(.success(publicURL.absoluteString))
            } catch {
                print("[TrainerService] uploadProfileImage failed: \(error)")
                completion(.failure(error))
            }
        }
    }
}
