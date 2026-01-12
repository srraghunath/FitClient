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

    private struct ActivityDateRequest: Encodable {
        let p_date: String
    }

    private struct ActivityUpsertRequest: Encodable {
        let p_date: String
        let p_workout: Bool
        let p_cardio: Bool
        let p_water: Bool
        let p_diet: Bool
        let p_sleep: Bool
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
                let rows: [DayActivityDTO] = try await supabase
                    .rpc("get_day_activity_for_date", params: ActivityDateRequest(p_date: dateString))
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
                let rows: [DayActivityDTO] = try await supabase
                    .rpc(
                        "upsert_day_activity",
                        params: ActivityUpsertRequest(
                            p_date: isoDate(from: date),
                            p_workout: record.workoutDone,
                            p_cardio: record.cardioDone,
                            p_water: record.waterDone,
                            p_diet: record.dietDone,
                            p_sleep: record.sleepDone
                        )
                    )
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
}
