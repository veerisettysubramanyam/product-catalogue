import Foundation

enum APIError: Error, Equatable {
    case invalidRequest
    /// Couldn't reach the server at all (offline, backend not running, timeout).
    case network
    case invalidResponse
    case decoding
    /// Server answered with a non-2xx status. `message` is the backend's user-safe message.
    case server(status: Int, code: String?, message: String?, fieldErrors: [String: String])

    var userMessage: String {
        switch self {
        case .network:
            return "Can't reach the server. Check your connection and try again."
        case .server(_, _, let message?, _):
            return message
        case .server(let status, _, nil, _) where status == 404:
            return "We couldn't find that."
        case .invalidRequest, .invalidResponse, .decoding, .server:
            return "Something went wrong. Please try again."
        }
    }
}

enum ErrorMessage {
    static func from(_ error: Error) -> String {
        (error as? APIError)?.userMessage ?? "Something went wrong. Please try again."
    }
}
