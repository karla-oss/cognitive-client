import Foundation

/// REST client for session lifecycle: create, get, end, feedback.
class SessionManager {
    private let baseURL: String
    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    // MARK: - POST /api/v1/sessions
    
    func createSession(userID: String, completion: @escaping (Result<CreateSessionResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/v1/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? encoder.encode(CreateSessionRequest(userID: userID))
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let self = self else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                let session = try self.decoder.decode(CreateSessionResponse.self, from: data)
                completion(.success(session))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - GET /api/v1/sessions/{id}
    
    func getSession(id: String, completion: @escaping (Result<CreateSessionResponse, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/v1/sessions/\(id)")!
        
        session.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let self = self else {
                completion(.failure(APIError.noData))
                return
            }
            do {
                let session = try self.decoder.decode(CreateSessionResponse.self, from: data)
                completion(.success(session))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - POST /api/v1/sessions/{id}/end
    
    func endSession(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/v1/sessions/\(id)/end")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        session.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }.resume()
    }
    
    // MARK: - POST /api/v1/feedback
    
    func submitFeedback(_ feedback: FeedbackRequest, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "\(baseURL)/api/v1/feedback")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? encoder.encode(feedback)
        
        session.dataTask(with: request) { _, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }.resume()
    }
}

enum APIError: Error, LocalizedError {
    case noData
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noData: return "No data received"
        case .invalidResponse: return "Invalid server response"
        }
    }
}
