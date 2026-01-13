import Foundation
import Supabase

struct DayPlan: Codable {
    let dayOfWeek: Int
    let sleepHours: Double?
    let waterLiters: Double?
    let cardioNotes: String?

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case sleepHours = "sleep_hours"
        case waterLiters = "water_intake_liters"
        case cardioNotes = "cardio_notes"
    }
}

final class DayPlanService {
    static let shared = DayPlanService()
    private let supabase = AuthService.shared.supabase

    private init() {}

    func fetchPlan(for clientId: UUID, dayOfWeek: Int, completion: @escaping (Result<DayPlan?, Error>) -> Void) {
        Task {
            do {
                let rows: [DayPlan] = try await supabase
                    .from("sessions")
                    .select("day_of_week,sleep_hours,water_intake_liters,cardio_notes")
                    .eq("client_id", value: clientId.uuidString)
                    .eq("day_of_week", value: dayOfWeek)
                    .limit(1)
                    .execute()
                    .value
                completion(.success(rows.first))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private struct UpsertDayPlanParams: Encodable {
        let p_client_id: String
        let p_day_of_week: Int
        let p_sleep_hours: Double
        let p_water_intake_liters: Double
        let p_cardio_notes: String
    }

    func savePlan(
        for clientId: UUID,
        dayOfWeek: Int,
        sleepHours: Double,
        waterLiters: Double,
        cardioNotes: String,
        completion: @escaping (Error?) -> Void
    ) {
        Task {
            do {
                let params = UpsertDayPlanParams(
                    p_client_id: clientId.uuidString,
                    p_day_of_week: dayOfWeek,
                    p_sleep_hours: sleepHours,
                    p_water_intake_liters: waterLiters,
                    p_cardio_notes: cardioNotes
                )

                let _: PostgrestResponse<Void> = try await supabase
                    .rpc("upsert_day_plan", params: params)
                    .execute()

                completion(nil)
            } catch {
                completion(error)
            }
        }
    }


    // Client-facing fetch based on date (uses auth user)
    func fetchPlanForClient(date: Date) async throws -> DayPlan? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)

        let rows: [DayPlan] = try await supabase
            .rpc("get_client_day_plan", params: ["p_date": dateString])
            .execute()
            .value

        return rows.first
    }
}
