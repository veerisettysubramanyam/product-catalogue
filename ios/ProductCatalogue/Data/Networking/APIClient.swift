import Foundation

/// Thin JSON-over-HTTP client for our backend. Knows nothing about products.
struct APIClient: Sendable {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func get<Response: Decodable>(_ path: String, query: [URLQueryItem] = []) async throws -> Response {
        let request = try makeRequest(path: path, query: query, method: "GET", body: nil)
        return try await send(request)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let data: Data
        do {
            data = try JSONEncoder().encode(body)
        } catch {
            throw APIError.invalidRequest
        }
        let request = try makeRequest(path: path, query: [], method: "POST", body: data)
        return try await send(request)
    }

    // MARK: - Private

    private func makeRequest(path: String, query: [URLQueryItem], method: String, body: Data?) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else { throw APIError.invalidRequest }

        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        guard (200..<300).contains(http.statusCode) else {
            let envelope = try? JSONDecoder().decode(ErrorEnvelopeDTO.self, from: data)
            let fieldErrors = Dictionary(
                (envelope?.error.details ?? []).map { ($0.field, $0.message) },
                uniquingKeysWith: { first, _ in first }
            )
            throw APIError.server(
                status: http.statusCode,
                code: envelope?.error.code,
                message: envelope?.error.message,
                fieldErrors: fieldErrors
            )
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
