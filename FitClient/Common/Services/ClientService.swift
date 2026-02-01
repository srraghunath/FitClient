import Foundation
import Supabase

final class ClientService {
    static let shared = ClientService()
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://xhxyhexaoxnejrsusfhb.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoeHloZXhhb3huZWpyc3VzZmhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczMTIzMzcsImV4cCI6MjA4Mjg4ODMzN30.1v1t-y6wgcgzOTByyEcLT4_O8gw17sjlD5-wqHgJhL8"
    )

    private init() {}

    func fetchClients(for trainerId: UUID, completion: @escaping (Result<[Client], Error>) -> Void) {
        print("Fetching clients for trainer ID: \(trainerId)")
        Task {
            do {
                let clients: [Client] = try await supabase
                    .from("clients")
                    .select()
                    .eq("trainer_id", value: trainerId.uuidString)
                    .execute()
                    .value

                print("Successfully fetched \(clients.count) clients.")
                completion(.success(clients))
            } catch {
                print("Error fetching clients: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func addClient(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Attempting to add client with email: \(email)")
        Task {
            do {
                try await supabase.rpc(
                    "add_client_to_trainer",
                    params: ["client_email": email]
                )
                .execute()

                print("Successfully added client with email: \(email)")
                completion(.success(()))
            } catch {
                print("Error adding client: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    // MARK: - Disconnect Client

    /// Disconnects a client from their trainer and purges shared data (sessions, conversations/messages, day activity), then unlinks trainer_id.
    func disconnectClientAndPurgeData(clientId: UUID, completion: @escaping (Error?) -> Void) {
        Task {
            do {
                // Use definer-secured RPC to cascade delete shared data and unlink
                try await supabase
                    .rpc("disconnect_client_cascade", params: ["p_client_id": clientId.uuidString])
                    .execute()

                // Remove locally cached schedule, if any
                removeLocalScheduleCache()

                completion(nil)
            } catch {
                print("[ClientService] disconnectClientAndPurgeData failed: \(error)")
                completion(error)
            }
        }
    }
}

private extension ClientService {
    func removeLocalScheduleCache() {
        let fileManager = FileManager.default
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let scheduleFile = documentsURL.appendingPathComponent("clientSchedulesData.json")
            if fileManager.fileExists(atPath: scheduleFile.path) {
                do {
                    try fileManager.removeItem(at: scheduleFile)
                    print("[ClientService] Removed local schedule cache at \(scheduleFile.path)")
                } catch {
                    print("[ClientService] Failed to remove local schedule cache: \(error)")
                }
            }
        }
    }
}
