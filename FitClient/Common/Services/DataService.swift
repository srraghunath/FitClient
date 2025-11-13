

import Foundation

class DataService {
    
    static let shared = DataService()
    
    private init() {}
    
    // MARK: - Clients
    
    func loadClients(completion: @escaping (Result<[Client], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let clientsData = try decoder.decode(ClientsData.self, from: data)
            completion(.success(clientsData.clients))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Sessions
    
    func loadSessions(completion: @escaping (Result<SessionsData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "sessionsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("sessionsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let sessionsData = try decoder.decode(SessionsData.self, from: data)
            completion(.success(sessionsData))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Chats
    
    func loadChats(completion: @escaping (Result<[ChatData], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "chatsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("chatsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let chatsResponse = try decoder.decode(ChatsResponse.self, from: data)
            completion(.success(chatsResponse.chats))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    func loadChat(forClientId clientId: String, completion: @escaping (Result<ChatData, Error>) -> Void) {
        loadChats { result in
            switch result {
            case .success(let chats):
                if let chat = chats.first(where: { $0.clientId == clientId }) {
                    completion(.success(chat))
                } else {
                    completion(.failure(DataServiceError.chatNotFound(clientId)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Client Profile
    
    func loadClientProfile(forClientId clientId: String, completion: @escaping (Result<ClientProfile, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientProfileData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientProfileData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profileData = try decoder.decode(ClientProfileData.self, from: data)
            
            if let profile = profileData.profiles[clientId] {
                completion(.success(profile))
            } else {
                completion(.failure(DataServiceError.clientProfileNotFound(clientId)))
            }
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Trainer Profile
    
    func loadTrainer(completion: @escaping (Result<Trainer, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "trainerData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("trainerData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let trainerData = try decoder.decode(TrainerData.self, from: data)
            completion(.success(trainerData.trainer))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Client Schedules
    
    func loadClientSchedule(forClientId clientId: String, completion: @escaping (Result<ClientScheduleData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientSchedulesData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientSchedulesData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let schedulesResponse = try decoder.decode(ClientSchedulesResponse.self, from: data)
            
            if let schedule = schedulesResponse.schedules.first(where: { $0.clientId == clientId }) {
                completion(.success(schedule))
            } else {
                completion(.failure(DataServiceError.clientScheduleNotFound(clientId)))
            }
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Workouts
    
    func loadWorkouts(completion: @escaping (Result<[Workout], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "workoutsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("workoutsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let workoutsData = try decoder.decode(WorkoutsData.self, from: data)
            completion(.success(workoutsData.workouts))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Client Dashboard
    
    func loadClientDashboard(completion: @escaping (Result<ClientDashboard, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientDashboardData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientDashboardData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dashboardData = try decoder.decode(ClientDashboardData.self, from: data)
            completion(.success(dashboardData.dashboard))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    func loadWorkoutsForDate(_ date: Date, completion: @escaping (Result<[TodayWorkout], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientDashboardData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientDashboardData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dashboardData = try decoder.decode(ClientDashboardData.self, from: data)
            
            // Format date as "yyyy-MM-dd"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            // Get workouts for the specific date
            if let workouts = dashboardData.workoutsByDate[dateString] {
                completion(.success(workouts))
            } else {
                // Return empty array if no workouts for this date
                completion(.success([]))
            }
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
}

// MARK: - Custom Errors

enum DataServiceError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)
    case chatNotFound(String)
    case clientProfileNotFound(String)
    case clientScheduleNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Error: \(fileName) not found"
        case .decodingFailed(let error):
            return "Error loading data: \(error.localizedDescription)"
        case .chatNotFound(let clientId):
            return "Chat not found for client: \(clientId)"
        case .clientProfileNotFound(let clientId):
            return "Profile not found for client: \(clientId)"
        case .clientScheduleNotFound(let clientId):
            return "Schedule not found for client: \(clientId)"
        }
    }
}
