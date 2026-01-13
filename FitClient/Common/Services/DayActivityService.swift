import Foundation
import Supabase

struct DayActivityDTO: Codable {
    let activityDate: String
    let workoutDone: Bool
    let cardioDone: Bool
    let waterDone: Bool
    let dietDone: Bool
    let sleepDone: Bool

    enum CodingKeys: String, CodingKey {
        case activityDate = "activity_date"
        case workoutDone = "workout_done"
        case cardioDone = "cardio_done"
        case waterDone = "water_done"
        case dietDone = "diet_done"
        case sleepDone = "sleep_done"
    }
}

final class DayActivityService {
    static let shared = DayActivityService()
    private let supabase = AuthService.shared.supabase

    private struct ActivityTableRow: Encodable {
        let activity_date: String
        let workout_done: Bool
        let cardio_done: Bool
        let water_done: Bool
        let diet_done: Bool
        let sleep_done: Bool
        let client_id: UUID
    }

    private init() {}

    private func isoDate(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func fetchActivity(
        for date: Date,
        completion: @escaping (Result<DayActivityDTO, Error>) -> Void
    ) {
        let dateString = isoDate(from: date)
        Task {
            do {
                let clientId = try await ensureClientId()

                let rows: [DayActivityDTO] = try await supabase
                    .from("client_day_activity")
                    .select()
                    .eq("client_id", value: clientId.uuidString)
                    .eq("activity_date", value: dateString)
                    .limit(1)
                    .execute()
                    .value

                if let first = rows.first {
                    completion(.success(first))
                } else {
                    completion(.success(DayActivityDTO(
                        activityDate: dateString,
                        workoutDone: false,
                        cardioDone: false,
                        waterDone: false,
                        dietDone: false,
                        sleepDone: false
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    func upsertActivity(
        for date: Date,
        record: DayActivityDTO,
        completion: @escaping (Result<DayActivityDTO, Error>) -> Void
    ) {
        Task {
            do {
                let clientId = try await ensureClientId()
                let row = ActivityTableRow(
                    activity_date: isoDate(from: date),
                    workout_done: record.workoutDone,
                    cardio_done: record.cardioDone,
                    water_done: record.waterDone,
                    diet_done: record.dietDone,
                    sleep_done: record.sleepDone,
                    client_id: clientId
                )

                // Manual upsert to avoid table/constraint ambiguity
                _ = try await supabase
                    .from("client_day_activity")
                    .delete()
                    .eq("client_id", value: clientId.uuidString)
                    .eq("activity_date", value: row.activity_date)
                    .execute()

                let rows: [DayActivityDTO] = try await supabase
                    .from("client_day_activity")
                    .insert(row)
                    .select()
                    .execute()
                    .value

                if let saved = rows.first {
                    completion(.success(saved))
                } else {
                    completion(.failure(NSError(
                        domain: "DayActivityService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty response from upsert_day_activity"]
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    private func ensureClientId() async throws -> UUID {
        if let cached = AuthService.shared.cachedRole {
            if case let .client(_, clientId, _) = cached { return clientId }
        }

        guard let role = try await AuthService.shared.resolveCurrentRole(), case let .client(_, clientId, _) = role else {
            throw NSError(domain: "DayActivityService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No client role found for current user"])
        }
        return clientId
    }
}
