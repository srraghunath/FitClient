import Foundation

// Remote workout payloads
private struct RemoteExercise: Decodable {
    let id: String
    let name: String
    let description: String?
    let image_url: String?
    let category: String?
}

private struct RemoteExerciseMinimal: Decodable {
    let name: String
    let image: String?
}

class DataService {

    static let shared = DataService()
    private let workoutsURL = URL(
        string:
            "https://raw.githubusercontent.com/srraghunath/FitClient/refs/heads/main/exercises.json"
    )!
    private let dietsURL = URL(
        string: "https://raw.githubusercontent.com/srraghunath/FitClient/refs/heads/main/foods.json"
    )!
    private var workoutsTask: Task<[Workout], Error>?
    private var dietsTask: Task<[Diet], Error>?

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

    func loadChat(
        forClientId clientId: String, completion: @escaping (Result<ChatData, Error>) -> Void
    ) {
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

    func loadClientProfile(
        forClientId clientId: String, completion: @escaping (Result<ClientProfile, Error>) -> Void
    ) {
        guard let url = Bundle.main.url(forResource: "clientProfileData", withExtension: "json")
        else {
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

    func loadClientSchedule(
        forClientId clientId: String,
        completion: @escaping (Result<ClientScheduleData, Error>) -> Void
    ) {
        // Prefer persisted copy in Documents (written by schedule save), fallback to bundled JSON.
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let documentsFile = documentsURL?.appendingPathComponent("clientSchedulesData.json")

        func load(from url: URL) throws -> ClientSchedulesResponse {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(ClientSchedulesResponse.self, from: data)
        }

        do {
            let response: ClientSchedulesResponse
            if let doc = documentsFile, fileManager.fileExists(atPath: doc.path) {
                response = try load(from: doc)
            } else if let bundleURL = Bundle.main.url(
                forResource: "clientSchedulesData", withExtension: "json")
            {
                response = try load(from: bundleURL)
            } else {
                completion(.failure(DataServiceError.fileNotFound("clientSchedulesData.json")))
                return
            }

            if let schedule = response.schedules.first(where: { $0.clientId == clientId }) {
                completion(.success(schedule))
            } else {
                completion(.failure(DataServiceError.clientScheduleNotFound(clientId)))
            }
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }

    // MARK: - Workouts

    func prefetchWorkoutsInBackground() {
        guard workoutsTask == nil else { return }
        workoutsTask = Task.detached { [weak self] in
            guard let self = self else { return [] }
            return try await self.fetchRemoteWorkouts()
        }
    }

    func prefetchDietsInBackground() {
        guard dietsTask == nil else { return }
        dietsTask = Task.detached { [weak self] in
            guard let self = self else { return [] }
            return try await self.fetchRemoteDiets()
        }
    }

    func loadWorkouts(completion: @escaping (Result<[Workout], Error>) -> Void) {
        if let task = workoutsTask {
            Task {
                do { completion(.success(try await task.value)) } catch {
                    completion(.failure(error))
                }
            }
            return
        }

        let task = Task { [weak self] () throws -> [Workout] in
            guard let self = self else { return [] }
            return try await self.fetchRemoteWorkouts()
        }
        workoutsTask = task

        Task {
            do { completion(.success(try await task.value)) } catch { completion(.failure(error)) }
        }
    }

    private func fetchRemoteWorkouts() async throws -> [Workout] {
        let (data, response) = try await URLSession.shared.data(from: workoutsURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DataServiceError.fileNotFound("Remote workouts fetch failed")
        }

        let decoder = JSONDecoder()

        // Primary attempt: array of detailed exercises (id, name, description, image_url, category)
        if let detailed = try? decoder.decode([RemoteExercise].self, from: data) {
            return mapDetailedExercises(detailed)
        }

        // Secondary attempt: category buckets {"upper": [...], "lower": [...], "full": [...]}
        if let buckets = try? decoder.decode([String: [RemoteExerciseMinimal]].self, from: data) {
            return mapBucketedExercises(buckets)
        }

        throw DataServiceError.decodingFailed(
            NSError(
                domain: "DataService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unexpected workouts payload"]))
    }

    private func mapDetailedExercises(_ items: [RemoteExercise]) -> [Workout] {
        items.map { item in
            Workout(
                id: item.id,
                name: item.name,
                description: item.description ?? "",
                imageUrl: item.image_url ?? "",
                category: mapCategory(item.category),
                isSelected: false,
                targetSets: nil,
                targetReps: nil
            )
        }
    }

    private func mapBucketedExercises(_ buckets: [String: [RemoteExerciseMinimal]]) -> [Workout] {
        var result: [Workout] = []
        let mapping: [(key: String, category: WorkoutCategory)] = [
            ("upper", .upperBody),
            ("lower", .lowerBody),
            ("full", .fullBody),
        ]
        for (key, category) in mapping {
            guard let list = buckets[key] else { continue }
            list.enumerated().forEach { idx, ex in
                let id = "remote_\(key)_\(idx)"
                result.append(
                    Workout(
                        id: id,
                        name: ex.name,
                        description: "",
                        imageUrl: ex.image ?? "",
                        category: category,
                        isSelected: false,
                        targetSets: nil,
                        targetReps: nil
                    )
                )
            }
        }
        return result
    }

    private func mapCategory(_ raw: String?) -> WorkoutCategory {
        switch raw?.lowercased() {
        case "upper_body", "upper": return .upperBody
        case "lower_body", "lower": return .lowerBody
        default: return .fullBody
        }
    }

    // MARK: - Pexels

    private struct PexelsSearchResponse: Decodable {
        let photos: [PexelsPhoto]
    }

    private struct PexelsPhoto: Decodable {
        let src: PexelsPhotoSrc
    }

    private struct PexelsPhotoSrc: Decodable {
        let medium: String
        let large: String?
    }

    private func fetchPexelsImageURL(query: String) async throws -> String? {
        guard var components = URLComponents(string: "https://api.pexels.com/v1/search") else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "orientation", value: "landscape"),
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        //REPALCE WITH PROD KEY ON PRODUCTION
        request.setValue(
            "Ds1sd2CoAqUX9lAHfu3zUPqWVEZZjksyqfyADNpFpGfwnlRRkFe3BxJ7",
            forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw DataServiceError.networkFailed("Pexels status code: \(http.statusCode)")
        }

        let decoded = try JSONDecoder().decode(PexelsSearchResponse.self, from: data)
        return decoded.photos.first?.src.large ?? decoded.photos.first?.src.medium
    }

    func loadWorkoutTargetPresets(
        completion: @escaping (Result<[WorkoutTargetPreset], Error>) -> Void
    ) {
        guard let url = Bundle.main.url(forResource: "workoutTargetsSample", withExtension: "json")
        else {
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
        if let task = dietsTask {
            Task {
                do { completion(.success(try await task.value)) } catch {
                    completion(.failure(error))
                }
            }
            return
        }

        let task = Task { [weak self] () throws -> [Diet] in
            guard let self = self else { return [] }
            return try await self.fetchRemoteDiets()
        }
        dietsTask = task

        Task {
            do { completion(.success(try await task.value)) } catch { completion(.failure(error)) }
        }
    }

    private struct RemoteDiet: Decodable {
        let id: String
        let name: String
        let protein: Double
        let carbs: Double
        let fat: Double
        let calories: Int
        let meal_type: String
        let diet_type: String
    }

    private func fetchRemoteDiets() async throws -> [Diet] {
        let (data, response) = try await URLSession.shared.data(from: dietsURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DataServiceError.fileNotFound("Remote diets fetch failed")
        }

        let decoder = JSONDecoder()
        let remote = try decoder.decode([RemoteDiet].self, from: data)

        var mapped: [Diet] = remote.map { item -> Diet in
            let dietType = mapDietType(rawType: item.diet_type, name: item.name)
            return Diet(
                id: item.id,
                name: item.name,
                grams: 100,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                calories: item.calories,
                imageUrl: "",
                mealType: MealType(rawValue: item.meal_type.lowercased()) ?? .lunch,
                dietType: dietType,
                quantity: 1,
                isSelected: false
            )
        }

        // Prefetch images for the first 5 items per (mealType, dietType) bucket using Pexels and cache to disk
        try await prefetchDietImages(&mapped)

        return mapped
    }

    private func prefetchDietImages(_ diets: inout [Diet]) async throws {
        let cacheDir = dietImageCacheDirectory()
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

        let buckets = Dictionary(
            grouping: diets, by: { DietBucket(mealType: $0.mealType, dietType: $0.dietType) })

        var remainingDownloads = 10

        for (_, list) in buckets {
            for diet in list.prefix(3) {
                if let localPath = cachedDietImagePath(for: diet.id),
                    FileManager.default.fileExists(atPath: localPath.path)
                {
                    updateDiet(&diets, id: diet.id, imageUrl: localPath.absoluteString)
                    continue
                }

                guard remainingDownloads > 0 else { continue }

                if let remoteUrlString = try? await fetchPexelsImageURL(query: diet.name),
                    let remoteURL = URL(string: remoteUrlString)
                {
                    remainingDownloads -= 1

                    if let data = try? Data(contentsOf: remoteURL),
                        let localPath = saveDietImageData(data, dietId: diet.id)
                    {
                        updateDiet(&diets, id: diet.id, imageUrl: localPath.absoluteString)
                    } else {
                        updateDiet(&diets, id: diet.id, imageUrl: remoteUrlString)
                    }
                }
            }
        }
    }

    private struct DietBucket: Hashable {
        let mealType: MealType
        let dietType: DietType
    }

    private func mapDietType(rawType: String, name: String) -> DietType {
        let lowered = rawType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleaned = lowered
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        if cleaned.contains("non") { return .nonVeg }
        if cleaned.contains("vegan") { return .vegan }

        // Heuristic: if name suggests meat but type not marked, treat as non-veg
        let meatKeywords = ["chicken", "mutton", "beef", "pork", "fish", "egg", "prawn", "shrimp", "meat", "turkey", "ham"]
        let nameLower = name.lowercased()
        if meatKeywords.contains(where: { nameLower.contains($0) }) {
            return .nonVeg
        }

        return .veg
    }

    private func updateDiet(_ diets: inout [Diet], id: String, imageUrl: String) {
        if let idx = diets.firstIndex(where: { $0.id == id }) {
            diets[idx] = Diet(
                id: diets[idx].id,
                name: diets[idx].name,
                grams: diets[idx].grams,
                protein: diets[idx].protein,
                carbs: diets[idx].carbs,
                fat: diets[idx].fat,
                calories: diets[idx].calories,
                imageUrl: imageUrl,
                mealType: diets[idx].mealType,
                dietType: diets[idx].dietType,
                quantity: diets[idx].quantity,
                isSelected: diets[idx].isSelected
            )
        }
    }

    private func dietImageCacheDirectory() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return caches.appendingPathComponent("dietImages", isDirectory: true)
    }

    private func cachedDietImagePath(for dietId: String) -> URL? {
        let file = dietImageCacheDirectory().appendingPathComponent("\(dietId).jpg")
        return file
    }

    private func saveDietImageData(_ data: Data, dietId: String) -> URL? {
        guard let path = cachedDietImagePath(for: dietId) else { return nil }
        do {
            try data.write(to: path, options: .atomic)
            return path
        } catch {
            return nil
        }
    }

    // On-demand diet image fetch/store for user taps
    func fetchAndCacheDietImage(for diet: Diet, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            // 1) If cached file exists, return immediately
            if let localPath = cachedDietImagePath(for: diet.id), FileManager.default.fileExists(atPath: localPath.path) {
                completion(.success(localPath.absoluteString))
                return
            }

            // 2) If diet.imageUrl is already remote, try downloading and caching
            if !diet.imageUrl.isEmpty, let remoteURL = URL(string: diet.imageUrl) {
                if let data = try? Data(contentsOf: remoteURL), let saved = saveDietImageData(data, dietId: diet.id) {
                    completion(.success(saved.absoluteString))
                    return
                }
            }

            // 3) Fallback to Pexels lookup using the diet name
            do {
                if let remoteUrlString = try await fetchPexelsImageURL(query: diet.name), let remoteURL = URL(string: remoteUrlString) {
                    let (data, response) = try await URLSession.shared.data(from: remoteURL)
                    if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode), let saved = saveDietImageData(data, dietId: diet.id) {
                        completion(.success(saved.absoluteString))
                    } else {
                        completion(.success(remoteUrlString))
                    }
                } else {
                    completion(.failure(DataServiceError.fileNotFound("Pexels result not found")))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Settings (Client & Trainer)

    func loadClientSettings(completion: @escaping (Result<ClientSettingsConfig, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientSettingsData", withExtension: "json")
        else {
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
        guard let url = Bundle.main.url(forResource: "trainerSettingsData", withExtension: "json")
        else {
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

    // MARK: - Client Dashboard

    func loadClientDashboard(completion: @escaping (Result<ClientDashboard, Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientDashboardData", withExtension: "json")
        else {
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

    func loadWorkoutsForDate(
        _ date: Date, completion: @escaping (Result<[TodayWorkout], Error>) -> Void
    ) {
        Task {
            do {
                // Fetch trainer-scheduled workout targets for this date from Supabase
                let plan = try await DayPlanService.shared.fetchPlanForClient(date: date)
                let details = plan?.workoutDetails ?? []

                // Load workout catalog (remote JSON) to hydrate names/images
                let catalog: [String: Workout] = try await withCheckedThrowingContinuation { cont in
                    self.loadWorkouts { result in
                        switch result {
                        case .success(let workouts):
                            let dict = Dictionary(
                                uniqueKeysWithValues: workouts.map { ($0.id, $0) })
                            cont.resume(returning: dict)
                        case .failure(let error):
                            cont.resume(throwing: error)
                        }
                    }
                }

                // Map workout details (targets) to TodayWorkout models for the dashboard list
                let todayWorkouts: [TodayWorkout] = details.compactMap { detail in
                    guard
                        let workout = catalog[detail.workoutId],
                        let sets = detail.targetSets,
                        let reps = detail.targetReps
                    else { return nil }

                    return TodayWorkout(
                        id: workout.id,
                        name: workout.name,
                        reps: "Do \(sets) sets of \(reps) reps",
                        imageUrl: workout.imageUrl
                    )
                }

                completion(.success(todayWorkouts))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Day Activity (Day Tracker)

    /// Loads the day tracker completion flags for a specific date from clientActivityData.json
    /// - Parameter date: The date to fetch completion for
    /// - Returns: Completion with a DayActivityCompletion if present, otherwise defaults to all false
    func loadDayActivityForDate(
        _ date: Date, completion: @escaping (Result<DayActivityCompletion, Error>) -> Void
    ) {
        guard let url = Bundle.main.url(forResource: "clientActivityData", withExtension: "json")
        else {
            completion(.failure(DataServiceError.fileNotFound("clientActivityData.json")))
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let activityData = try decoder.decode(ClientMonthlyActivityData.self, from: data)

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy-MM"

            let targetDateString = formatter.string(from: date)
            let monthKey = monthFormatter.string(from: date)

            if let monthDays = activityData.monthlyData[monthKey],
                let day = monthDays.first(where: { $0.date == targetDateString })
            {
                completion(.success(day))
            } else {
                // Default all false if no entry
                let empty = DayActivityCompletion(
                    date: targetDateString, workout: false, diet: false, sleep: false,
                    waterIntake: false, cardio: false)
                completion(.success(empty))
            }
        } catch {
            completion(.failure(DataServiceError.decodingFailed(error)))
        }
    }

    func loadDietForDate(_ date: Date, completion: @escaping (Result<[TodayMeal], Error>) -> Void) {
        guard let url = Bundle.main.url(forResource: "clientDashboardData", withExtension: "json")
        else {
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
        guard let url = Bundle.main.url(forResource: "settingsMenuData", withExtension: "json")
        else {
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
        guard let url = Bundle.main.url(forResource: "signupOptionsData", withExtension: "json")
        else {
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
        guard let url = Bundle.main.url(forResource: "chatResponsesData", withExtension: "json")
        else {
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
}

// MARK: - Custom Errors

enum DataServiceError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)
    case chatNotFound(String)
    case clientProfileNotFound(String)
    case clientScheduleNotFound(String)
    case networkFailed(String)

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
        case .networkFailed(let msg):
            return "Network error: \(msg)"
        }
    }
}
