import Foundation
import Supabase

struct TrainerSessionDTO: Decodable {
    let sessionId: UUID
    let clientId: UUID
    let clientName: String
    let clientProfileImageUrl: String?
    let goal: String?
    let startTime: String?
    let endTime: String?
    let note: String?
    let sessionDate: String
    let dayOfWeek: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case clientId = "client_id"
        case clientName = "client_name"
        case clientProfileImageUrl = "client_profile_image_url"
        case goal
        case startTime = "start_time"
        case endTime = "end_time"
        case note
        case sessionDate = "session_date"
        case dayOfWeek = "day_of_week"
    }
}

final class SessionService {
    static let shared = SessionService()
    private let supabase = AuthService.shared.supabase

    private struct SessionsRangeRequest: Encodable {
        let p_start_date: String
        let p_days: Int
    }

    private init() {}

    func fetchSessions(
        startingFrom startDate: Date,
        days: Int = 7,
        completion: @escaping (Result<[TrainerSessionDTO], Error>) -> Void
    ) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: startDate)

        Task {
            do {
                let rows: [TrainerSessionDTO] = try await supabase
                    .rpc(
                        "get_trainer_sessions_for_range",
                        params: SessionsRangeRequest(p_start_date: dateString, p_days: days)
                    )
                    .execute()
                    .value

                completion(.success(rows))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
