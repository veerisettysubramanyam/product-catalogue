import Foundation
@testable import ProductCatalogue

/// HTTPClient double for repository tests. Responses are canned JSON per path and are
/// decoded with the real DTOs, so tests also cover the wire format → model mapping.
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    struct Call: Equatable {
        let method: String
        let path: String
        let query: [URLQueryItem]
        /// JSON body for POSTs, re-encoded so tests can assert on it.
        let body: Data?
    }

    private let lock = NSLock()
    private var responses: [String: Result<String, Error>] = [:]
    private var _calls: [Call] = []

    var calls: [Call] { lock.withLock { _calls } }

    func respond(to path: String, json: String) {
        lock.withLock { responses[path] = .success(json) }
    }

    func fail(_ path: String, with error: Error) {
        lock.withLock { responses[path] = .failure(error) }
    }

    func get<Response: Decodable>(_ path: String, query: [URLQueryItem]) async throws -> Response {
        try respond(Call(method: "GET", path: path, query: query, body: nil))
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try respond(Call(method: "POST", path: path, query: [], body: try JSONEncoder().encode(body)))
    }

    private func respond<Response: Decodable>(_ call: Call) throws -> Response {
        let result: Result<String, Error>? = lock.withLock {
            _calls.append(call)
            return responses[call.path]
        }
        guard let result else {
            throw MockHTTPClientError.noResponseConfigured(call.path)
        }
        return try JSONDecoder().decode(Response.self, from: Data(try result.get().utf8))
    }
}

enum MockHTTPClientError: Error, Equatable {
    case noResponseConfigured(String)
}

extension MockHTTPClient.Call {
    /// The POST body as a dictionary, for readable assertions.
    var jsonBody: [String: String]? {
        guard let body, let object = try? JSONSerialization.jsonObject(with: body) else { return nil }
        return object as? [String: String]
    }
}
