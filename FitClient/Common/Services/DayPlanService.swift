import Foundation
import Supabase

struct DayPlan: Codable {
    let dayOfWeek: Int
    let sleepHours: Double?
    let waterLiters: Double?
    let cardioNotes: String?
    let workoutDetails: [WorkoutScheduleDetail]?
    let dietPlan: [DietItem]?

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case sleepHours = "sleep_hours"
        case waterLiters = "water_intake_liters"
        case cardioNotes = "cardio_notes"
        case workoutDetails = "workout_details"
        case dietPlan = "diet_plan"
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
                    .select("day_of_week,sleep_hours,water_intake_liters,cardio_notes,workout_details,diet_plan")
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
        workoutDetails: [WorkoutScheduleDetail],
        dietPlan: [(dietId: String, quantity: Int)],
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

                // Persist workout targets to the new JSONB column
                struct PlanDetailsUpdate: Encodable {
                    let workout_details: [WorkoutScheduleDetail]
                    let diet_plan: [DietItem]
                }

                let dietItems = dietPlan.map { DietItem(dietId: $0.dietId, quantity: $0.quantity) }
                let updatePayload = PlanDetailsUpdate(workout_details: workoutDetails, diet_plan: dietItems)

                try await supabase
                    .from("sessions")
                    .update(updatePayload)
                    .eq("client_id", value: clientId.uuidString)
                    .eq("day_of_week", value: dayOfWeek)
                    .execute()

                completion(nil)
            } catch {
                completion(error)
            }
        }
    }


    // Client-facing fetch based on date (uses auth user)
    func fetchPlanForClient(date: Date) async throws -> DayPlan? {
        // Derive weekday index matching trainer save (0 = Monday ... 6 = Sunday)
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: date) // 1 = Sunday ... 7 = Saturday
        let weekdayIndex = (weekdayNumber + 5) % 7

        guard let authId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "DayPlanService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        // Map auth user -> client.id (sessions store client_id, not auth user id)
        struct ClientRow: Decodable { let id: String }
        let clients: [ClientRow] = try await supabase
            .from("clients")
            .select("id")
            .eq("user_id", value: authId)
            .limit(1)
            .execute()
            .value

        guard let clientId = clients.first?.id else { return nil }

        let rows: [DayPlan] = try await supabase
            .from("sessions")
            .select("day_of_week,sleep_hours,water_intake_liters,cardio_notes,workout_details,diet_plan")
            .eq("client_id", value: clientId)
            .eq("day_of_week", value: weekdayIndex)
            .limit(1)
            .execute()
            .value

        return rows.first
    }
}
