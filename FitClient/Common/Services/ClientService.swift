import Foundation
import Supabase

class ClientService {
    static let shared = ClientService()
    private let supabase = SupabaseClient(supabaseURL: URL(string: "https://xhxyhexaoxnejrsusfhb.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhoeHloZXhhb3huZWpyc3VzZmhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczMTIzMzcsImV4cCI6MjA4Mjg4ODMzN30.1v1t-y6wgcgzOTByyEcLT4_O8gw17sjlD5-wqHgJhL8")

    private init() {}

    func fetchClients(for trainerId: UUID, completion: @escaping (Result<[Client], Error>) -> Void) {
        print("Fetching clients for trainer ID: \(trainerId)")
        Task {
            do {
                let clients: [Client] = try await supabase.database
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
}
