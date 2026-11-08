import Foundation

/// What repositories need from the network: typed JSON GET/POST against our backend.
/// `APIClient` is the live implementation; tests use a mock. Repositories depend on
/// this protocol so transport concerns (auth headers, retries, logging) can change
/// without touching them.
protocol HTTPClient: Sendable {
    func get<Response: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> Response
    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response
}

extension HTTPClient {
    /// Protocols can't declare default arguments, so the no-query form lives here.
    func get<Response: Decodable>(_ path: String) async throws -> Response {
        try await get(path, query: [])
    }
}
