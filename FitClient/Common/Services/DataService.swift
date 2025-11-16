import Foundation

class DataService {
    
    static let shared = DataService()
    
    private let apiBaseURL = URL(string: "http://localhost:3000/api/")!
    private let urlSession: URLSession
    private let apiDecoder: JSONDecoder
    private let isoDateFormatter: ISO8601DateFormatter
    private let defaultSessionDuration: TimeInterval = 60 * 60
    
    private init(session: URLSession = .shared) {
        self.urlSession = session
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.apiDecoder = decoder
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoDateFormatter = isoFormatter
    }
    
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

    func loadClient(forClientId clientId: String, completion: @escaping (Result<Client, Error>) -> Void) {
        loadClients { result in
            switch result {
            case .success(let clients):
                if let client = clients.first(where: { $0.id == clientId }) {
                    completion(.success(client))
                } else {
                    completion(.failure(DataServiceError.clientNotFound(clientId)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Sessions
    
    func loadSessions(completion: @escaping (Result<SessionsData, Error>) -> Void) {
        fetchSessionsForAuthenticatedUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let sessionsData):
                completion(.success(sessionsData))
            case .failure(let error):
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .missingAuthToken, .invalidToken:
                        self.loadSessionsFromBundle(completion: completion)
                    default:
                        completion(.failure(error))
                    }
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func fetchSessionsForAuthenticatedUser(completion: @escaping (Result<SessionsData, Error>) -> Void) {
        do {
            let userId = try resolveAuthenticatedUserId()
            fetchSessions(forUserId: userId, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    func fetchSessions(forUserId userId: String, completion: @escaping (Result<SessionsData, Error>) -> Void) {
        sendRequest(path: "sessions/list/\(userId)", method: .get) { [weak self] (result: Result<SessionListPayload, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let payload):
                let sessionsData = self.transformSessions(from: payload.sessions)
                completion(.success(sessionsData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func loadSessionsFromBundle(completion: @escaping (Result<SessionsData, Error>) -> Void) {
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

    func createSession(clientId: String,
                       startTime: Date,
                       endTime: Date? = nil,
                       notes: String? = nil,
                       completion: @escaping (Result<Session, Error>) -> Void) {
        var payload: [String: Any] = [
            "clientId": clientId,
            "startTime": isoDateFormatter.string(from: startTime)
        ]

        let resolvedEndTime = endTime ?? startTime.addingTimeInterval(defaultSessionDuration)
        payload["endTime"] = isoDateFormatter.string(from: resolvedEndTime)

        if let notes = notes, !notes.isEmpty {
            payload["notes"] = notes
        }

        sendJSONRequest(path: "sessions", method: .post, jsonBody: payload) { [weak self] (result: Result<SessionAPIResponse, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let apiSession):
                let session = self.convertToSession(apiSession)
                completion(.success(session))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateSession(sessionId: String,
                       startTime: Date? = nil,
                       endTime: Date? = nil,
                       notes: String? = nil,
                       completion: @escaping (Result<Session, Error>) -> Void) {
        var payload: [String: Any] = [:]

        if let startTime = startTime {
            payload["startTime"] = isoDateFormatter.string(from: startTime)
            let resolvedEndTime = endTime ?? startTime.addingTimeInterval(defaultSessionDuration)
            payload["endTime"] = isoDateFormatter.string(from: resolvedEndTime)
        }

        if let endTime = endTime, payload["endTime"] == nil {
            payload["endTime"] = isoDateFormatter.string(from: endTime)
        }

        if let notes = notes {
            payload["notes"] = notes
        }

        guard !payload.isEmpty else {
            let error = NSError(domain: "DataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "At least one field is required to update a session."])
            completion(.failure(DataServiceError.encodingFailed(error)))
            return
        }

        sendJSONRequest(path: "sessions/\(sessionId)", method: .put, jsonBody: payload) { [weak self] (result: Result<SessionAPIResponse, Error>) in
            guard let self = self else { return }
            switch result {
            case .success(let apiSession):
                let session = self.convertToSession(apiSession)
                completion(.success(session))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteSession(sessionId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        sendRequest(path: "sessions/\(sessionId)", method: .delete) { (result: Result<EmptyResponse, Error>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func transformSessions(from apiSessions: [SessionAPIResponse]) -> SessionsData {
        guard !apiSessions.isEmpty else {
            return SessionsData(todaySessions: [], upcomingSessions: [])
        }

        let sortedSessions = apiSessions.sorted { $0.startTime < $1.startTime }
        var todaySessions: [Session] = []
        var otherSessions: [Session] = []
        let calendar = Calendar.current

        for apiSession in sortedSessions {
            let session = convertToSession(apiSession)
            if calendar.isDateInToday(apiSession.startTime) {
                todaySessions.append(session)
            } else {
                otherSessions.append(session)
            }
        }

        return SessionsData(todaySessions: todaySessions, upcomingSessions: otherSessions)
    }

    private func convertToSession(_ apiSession: SessionAPIResponse) -> Session {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        timeFormatter.amSymbol = "AM"
        timeFormatter.pmSymbol = "PM"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let startDate = apiSession.startTime
        let endDate = apiSession.endTime ?? startDate.addingTimeInterval(defaultSessionDuration)
        let startTimeString = timeFormatter.string(from: startDate)
        let endTimeString = timeFormatter.string(from: endDate)
        let dateString = dateFormatter.string(from: startDate)

        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(startDate)

        let clientName = apiSession.clientName ?? apiSession.client?.fullName ?? "Client"
        let clientImage = apiSession.clientProfileImage ?? apiSession.client?.profileImage ?? ""

        return Session(id: apiSession.id,
                       clientId: apiSession.clientId,
                       clientName: clientName,
                       clientProfileImage: clientImage,
                       startTime: startTimeString,
                       endTime: endTimeString,
                       date: dateString,
                       isToday: isToday)
    }

    private func resolveAuthenticatedUserId() throws -> String {
        guard let token = AuthService.shared.getToken() else {
            throw NetworkError.missingAuthToken
        }

        let segments = token.split(separator: ".")
        guard segments.count >= 2 else {
            throw NetworkError.invalidToken
        }

        var base64 = String(segments[1])
        base64 = base64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let paddingLength = 4 - (base64.count % 4)
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        guard let payloadData = Data(base64Encoded: base64) else {
            throw NetworkError.invalidToken
        }

        let payload = try JSONDecoder().decode(JWTPayload.self, from: payloadData)
        return payload.id
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

    func loadClientProgress(forClientId clientId: String, completion: @escaping (Result<ClientActivityData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientActivityData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientActivityData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let clientActivityData = try JSONDecoder().decode(ClientActivityData.self, from: data)
            completion(.success(clientActivityData))
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
    
    func loadWorkoutTargetPresets(completion: @escaping (Result<[WorkoutTargetPreset], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "workoutTargetsSample", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("workoutTargetsSample.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let presetsData = try decoder.decode(WorkoutTargetPresetsData.self, from: data)
            completion(.success(presetsData.targets))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Diets
    
    func loadDiets(completion: @escaping (Result<[Diet], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "dietsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("dietsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dietsData = try decoder.decode(DietsData.self, from: data)
            completion(.success(dietsData.diets))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Settings (Client & Trainer)

    func loadClientSettings(completion: @escaping (Result<ClientSettingsConfig, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientSettingsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientSettingsData.json")))
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(ClientSettingsConfig.self, from: data)
            completion(.success(config))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }

    func loadTrainerSettings(completion: @escaping (Result<TrainerSettingsConfig, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "trainerSettingsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("trainerSettingsData.json")))
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(TrainerSettingsConfig.self, from: data)
            completion(.success(config))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }

    // MARK: - Trainer Dashboard (API)

    /// Links a client to the authenticated trainer using their email address.
    func linkClientToTrainer(clientEmail: String, completion: @escaping (Result<ClientTrainerLinkResponse, Error>) -> Void) {
        let payload: [String: Any] = ["clientEmail": clientEmail]
        sendJSONRequest(path: "trainer/clients", method: .post, jsonBody: payload, completion: completion)
    }

    /// Creates or updates a weekly schedule template for a specific client on a given day.
    func createOrUpdateWeeklyTemplate(for clientId: String,
                                      dayOfWeek: TrainerDayOfWeek,
                                      sleepTargetHours: Double?,
                                      waterTargetLiters: Double?,
                                      cardioPlanText: String?,
                                      completion: @escaping (Result<WeeklyScheduleTemplateResponse, Error>) -> Void) {
        var payload: [String: Any] = [:]
        if let sleepTargetHours = sleepTargetHours {
            payload["sleepTargetHours"] = sleepTargetHours
        }
        if let waterTargetLiters = waterTargetLiters {
            payload["waterTargetLiters"] = waterTargetLiters
        }
        if let cardioPlanText = cardioPlanText, !cardioPlanText.isEmpty {
            payload["cardioPlanText"] = cardioPlanText
        }

        let path = "schedule/template/\(clientId)/\(dayOfWeek.rawValue)"
        sendJSONRequest(path: path, method: .post, jsonBody: payload, completion: completion)
    }

    /// Adds a workout entry to an existing weekly schedule template.
    func addWorkoutToTemplate(templateId: String,
                              exerciseId: String,
                              sets: Int,
                              reps: String,
                              completion: @escaping (Result<ScheduledTemplateExerciseResponse, Error>) -> Void) {
        let payload: [String: Any] = [
            "exerciseId": exerciseId,
            "sets": sets,
            "reps": reps
        ]
        let path = "schedule/workout/\(templateId)"
        sendJSONRequest(path: path, method: .post, jsonBody: payload, completion: completion)
    }

    /// Adds a meal entry to an existing weekly schedule template.
    func addMealToTemplate(templateId: String,
                           foodItemId: String,
                           mealTime: TrainerMealTime,
                           quantityText: String?,
                           completion: @escaping (Result<ScheduledTemplateMealItemResponse, Error>) -> Void) {
        var payload: [String: Any] = [
            "foodItemId": foodItemId,
            "mealTime": mealTime.rawValue
        ]
        if let quantityText = quantityText, !quantityText.isEmpty {
            payload["quantityText"] = quantityText
        }
        let path = "schedule/meal/\(templateId)"
        sendJSONRequest(path: path, method: .post, jsonBody: payload, completion: completion)
    }

    /// Retrieves the activity summary for a client. The authenticated user must be a linked trainer.
    func fetchClientActivitySummary(clientId: String, completion: @escaping (Result<[ClientActivityLogResponse], Error>) -> Void) {
        sendRequest(path: "activity/summary/\(clientId)", method: .get, completion: completion)
    }

    /// Fetches the authenticated client's schedule template for the current day.
    func fetchTodaySchedule(completion: @escaping (Result<WeeklyScheduleTemplateDetailResponse, Error>) -> Void) {
        sendRequest(path: "schedule/today", method: .get, completion: completion)
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

    // MARK: - Day Activity (Day Tracker)

    /// Loads the day tracker completion flags for a specific date from clientActivityData.json
    /// - Parameter date: The date to fetch completion for
    /// - Returns: Completion with a DayActivityCompletion if present, otherwise defaults to all false
    func loadDayActivityForDate(_ date: Date, completion: @escaping (Result<DayActivityCompletion, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientActivityData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientActivityData.json")))
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let activityData = try decoder.decode(ClientMonthlyActivityData.self, from: data)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)

            dateFormatter.dateFormat = "yyyy-MM"
            let monthString = dateFormatter.string(from: date)

            if let monthlyData = activityData.monthlyData[monthString],
               let dayData = monthlyData.first(where: { $0.date == dateString }) {
                completion(.success(dayData))
            } else {
                // Return default values if no data for this date
                let defaultCompletion = DayActivityCompletion(date: dateString, workout: false, diet: false, sleep: false, waterIntake: false, cardio: false)
                completion(.success(defaultCompletion))
            }
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    func loadDietForDate(_ date: Date, completion: @escaping (Result<[TodayMeal], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientDashboardData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("clientDashboardData.json")))
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let dashboardData = try decoder.decode(ClientDashboardData.self, from: data)
            // For now, return the dashboard.todayDiet irrespective of date
            completion(.success(dashboardData.dashboard.todayDiet))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Settings Menu
    
    func loadSettingsMenuItems(completion: @escaping (Result<SettingsMenuData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "settingsMenuData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("settingsMenuData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let menuData = try decoder.decode(SettingsMenuData.self, from: data)
            completion(.success(menuData))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Signup Options
    
    func loadSignupOptions(completion: @escaping (Result<SignupOptionsData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "signupOptionsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("signupOptionsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let optionsData = try decoder.decode(SignupOptionsData.self, from: data)
            completion(.success(optionsData))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }
    
    // MARK: - Chat Responses
    
    func loadChatResponses(completion: @escaping (Result<ChatResponsesData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "chatResponsesData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("chatResponsesData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let responsesData = try decoder.decode(ChatResponsesData.self, from: data)
            completion(.success(responsesData))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }

    // MARK: - Networking Helpers

    private func sendJSONRequest<T: Decodable>(path: String,
                                               method: HTTPMethod,
                                               jsonBody: [String: Any],
                                               requiresAuth: Bool = true,
                                               completion: @escaping (Result<T, Error>) -> Void) {
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: jsonBody)
            sendRequest(path: path, method: method, body: bodyData, requiresAuth: requiresAuth, completion: completion)
        } catch {
            dispatchResult(.failure(NetworkError.encoding(error)), completion: completion)
        }
    }

    private func sendRequest<T: Decodable>(path: String,
                                           method: HTTPMethod,
                                           body: Data? = nil,
                                           requiresAuth: Bool = true,
                                           completion: @escaping (Result<T, Error>) -> Void) {
        do {
            let request = try makeRequest(path: path, method: method, body: body, requiresAuth: requiresAuth)
            performRequest(request, completion: completion)
        } catch {
            dispatchResult(.failure(error), completion: completion)
        }
    }

    private func makeRequest(path: String,
                             method: HTTPMethod,
                             body: Data?,
                             requiresAuth: Bool) throws -> URLRequest {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = apiBaseURL.appendingPathComponent(trimmedPath)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if requiresAuth {
            guard let token = AuthService.shared.getToken() else {
                throw NetworkError.missingAuthToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest,
                                              completion: @escaping (Result<T, Error>) -> Void) {
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                self.dispatchResult(.failure(NetworkError.transport(error)), completion: completion)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.dispatchResult(.failure(NetworkError.invalidResponse), completion: completion)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = self.extractErrorMessage(from: data)
                self.dispatchResult(.failure(NetworkError.httpError(statusCode: httpResponse.statusCode, message: message)), completion: completion)
                return
            }

            guard let data = data, !data.isEmpty else {
                if T.self == EmptyResponse.self, let empty = EmptyResponse() as? T {
                    self.dispatchResult(.success(empty), completion: completion)
                } else {
                    self.dispatchResult(.failure(NetworkError.emptyResponse), completion: completion)
                }
                return
            }

            do {
                let decoded = try self.apiDecoder.decode(T.self, from: data)
                self.dispatchResult(.success(decoded), completion: completion)
            } catch {
                self.dispatchResult(.failure(NetworkError.decoding(error)), completion: completion)
            }
        }.resume()
    }

    private func dispatchResult<T>(_ result: Result<T, Error>,
                                   completion: @escaping (Result<T, Error>) -> Void) {
        DispatchQueue.main.async {
            completion(result)
        }
    }

    private func extractErrorMessage(from data: Data?) -> String? {
        guard let data = data, !data.isEmpty else { return nil }

        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            if let message = apiError.error ?? apiError.message {
                return message
            }
            if let first = apiError.errors?.first {
                return first.message ?? first.msg
            }
        }

        if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let message = json["error"] as? String { return message }
            if let message = json["message"] as? String { return message }
        }

        return nil
    }
    
    // MARK: - UI Labels
    
    func loadUILabels(completion: @escaping (Result<UILabelsData, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "uiLabelsData", withExtension: "json") else {
            completion(.failure(DataServiceError.fileNotFound("uiLabelsData.json")))
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let labelsData = try decoder.decode(UILabelsData.self, from: data)
            completion(.success(labelsData))
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }

    // MARK: - Authentication/User Management
}

// MARK: - Networking Types

private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum NetworkError: LocalizedError {
    case invalidURL
    case missingAuthToken
    case transport(Error)
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case emptyResponse
    case decoding(Error)
    case encoding(Error)
    case invalidToken

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Failed to construct a valid URL for the request."
        case .missingAuthToken:
            return "Authentication token is missing. Please log in again."
        case .transport(let error):
            return error.localizedDescription
        case .invalidResponse:
            return "Received an invalid response from the server."
        case let .httpError(statusCode, message):
            if let message = message, !message.isEmpty {
                return message
            }
            return "Server returned an error (status code: \(statusCode))."
        case .emptyResponse:
            return "The server returned an empty response."
        case .decoding(let error):
            return "Failed to decode server response: \(error.localizedDescription)"
        case .encoding(let error):
            return "Failed to encode request body: \(error.localizedDescription)"
        case .invalidToken:
            return "Authentication token is invalid or malformed. Please log in again."
        }
    }
}

private struct EmptyResponse: Decodable {
    init() {}
}

private struct APIErrorResponse: Decodable {
    struct ValidationError: Decodable {
        let msg: String?
        let message: String?
    }

    let error: String?
    let message: String?
    let errors: [ValidationError]?
}

private struct SessionListPayload: Decodable {
    let sessions: [SessionAPIResponse]

    private enum CodingKeys: String, CodingKey {
        case sessions
        case data
        case items
    }

    init(from decoder: Decoder) throws {
        if let array = try? decoder.singleValueContainer().decode([SessionAPIResponse].self) {
            self.sessions = array
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let sessions = try container.decodeIfPresent([SessionAPIResponse].self, forKey: .sessions) {
            self.sessions = sessions
            return
        }

        if let data = try container.decodeIfPresent([SessionAPIResponse].self, forKey: .data) {
            self.sessions = data
            return
        }

        if let items = try container.decodeIfPresent([SessionAPIResponse].self, forKey: .items) {
            self.sessions = items
            return
        }

        throw DecodingError.dataCorruptedError(forKey: .sessions,
                                               in: container,
                                               debugDescription: "Expected an array of sessions in the API response.")
    }
}

private struct SessionAPIResponse: Decodable {
    let id: String
    let trainerId: String
    let clientId: String
    let startTime: Date
    let endTime: Date?
    let notes: String?
    let clientName: String?
    let clientProfileImage: String?
    let client: SessionUserSummary?
    let trainer: SessionUserSummary?
}

private struct SessionUserSummary: Decodable {
    let id: String
    let fullName: String?
    let email: String?
    let profileImage: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case fullName
        case email
        case profileImage
        case profileImageUrl
        case avatarUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        if let direct = try container.decodeIfPresent(String.self, forKey: .profileImage) {
            profileImage = direct
        } else if let url = try container.decodeIfPresent(String.self, forKey: .profileImageUrl) {
            profileImage = url
        } else if let avatar = try container.decodeIfPresent(String.self, forKey: .avatarUrl) {
            profileImage = avatar
        } else {
            profileImage = nil
        }
    }
}

private struct JWTPayload: Decodable {
    let id: String
    let role: String
}

// MARK: - Trainer API Models

enum TrainerDayOfWeek: String, CaseIterable {
    case monday = "MONDAY"
    case tuesday = "TUESDAY"
    case wednesday = "WEDNESDAY"
    case thursday = "THURSDAY"
    case friday = "FRIDAY"
    case saturday = "SATURDAY"
    case sunday = "SUNDAY"

    init?(weekday: Weekday) {
        switch weekday {
        case .monday: self = .monday
        case .tuesday: self = .tuesday
        case .wednesday: self = .wednesday
        case .thursday: self = .thursday
        case .friday: self = .friday
        case .saturday: self = .saturday
        case .sunday: self = .sunday
        }
    }
}

enum TrainerMealTime: String, CaseIterable {
    case breakfast = "BREAKFAST"
    case lunch = "LUNCH"
    case dinner = "DINNER"
    case snack = "SNACK"
}

struct ClientTrainerLinkResponse: Decodable {
    let id: String
    let trainerId: String
    let clientId: String
    let level: String?
    let isActive: Bool?
}

struct WeeklyScheduleTemplateResponse: Decodable {
    let id: String
    let clientId: String
    let dayOfWeek: String
    let sleepTargetHours: Double?
    let waterTargetLiters: Double?
    let cardioPlanText: String?
}

struct ScheduledTemplateExerciseResponse: Decodable {
    let id: String
    let templateId: String
    let exerciseId: String
    let sets: Int
    let reps: String
}

struct ScheduledTemplateMealItemResponse: Decodable {
    let id: String
    let templateId: String
    let foodItemId: String
    let mealTime: String
    let quantityText: String?
}

struct ClientActivityLogResponse: Decodable {
    let id: String
    let clientId: String
    let date: Date
    let isWorkoutCompleted: Bool
    let isDietCompleted: Bool
    let isCardioCompleted: Bool
    let isWaterGoalMet: Bool
    let isSleepGoalMet: Bool
}

struct WeeklyScheduleTemplateDetailResponse: Decodable {
    let id: String
    let clientId: String
    let dayOfWeek: String
    let sleepTargetHours: Double?
    let waterTargetLiters: Double?
    let cardioPlanText: String?
    let scheduledExercises: [ScheduledExerciseDetail]
    let scheduledMealItems: [ScheduledMealItemDetail]
}

struct ScheduledExerciseDetail: Decodable {
    let id: String
    let templateId: String
    let exerciseId: String
    let sets: Int
    let reps: String
    let exercise: ExerciseDetail?
}

struct ExerciseDetail: Decodable {
    let id: String
    let name: String
    let bodyPart: String
    let description: String?
}

struct ScheduledMealItemDetail: Decodable {
    let id: String
    let templateId: String
    let foodItemId: String
    let mealTime: String
    let quantityText: String?
    let foodItem: FoodItemDetail?
}

struct FoodItemDetail: Decodable {
    let id: String
    let name: String
    let calories: Int?
    let protein: Double?
    let carbs: Double?
    let fat: Double?
}

// MARK: - Custom Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case emailExists

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailExists:
            return "An account with this email already exists."
        }
    }
}

enum DataServiceError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)
    case encodingFailed(Error)
    case chatNotFound(String)
    case clientProfileNotFound(String)
    case clientScheduleNotFound(String)
    case clientNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Error: \(fileName) not found"
        case .decodingFailed(let error):
            return "Error loading data: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Error saving data: \(error.localizedDescription)"
        case .chatNotFound(let clientId):
            return "Chat not found for client: \(clientId)"
        case .clientProfileNotFound(let clientId):
            return "Profile not found for client: \(clientId)"
        case .clientScheduleNotFound(let clientId):
            return "Schedule not found for client: \(clientId)"
        case .clientNotFound(let clientId):
            return "Client not found: \(clientId)"
        }
    }
}
