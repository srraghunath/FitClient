//
//  DataService.swift
//  FitClient
//
//  Created on 06/11/25.
//

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
}

// MARK: - Custom Errors

enum DataServiceError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)
    case chatNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Error: \(fileName) not found"
        case .decodingFailed(let error):
            return "Error loading data: \(error.localizedDescription)"
        case .chatNotFound(let clientId):
            return "Chat not found for client: \(clientId)"
        }
    }
}
