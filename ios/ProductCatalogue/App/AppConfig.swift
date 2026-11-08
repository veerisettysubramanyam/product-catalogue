import Foundation

enum AppConfig {
    /// Backend base URL. Order: `API_BASE_URL` scheme env var, then the `APIBaseURL`
    /// Info.plist value (from the API_BASE_URL build setting), then localhost.
    static var apiBaseURL: URL {
        if let value = ProcessInfo.processInfo.environment["API_BASE_URL"], let url = validURL(value) {
            return url
        }
        if let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String, let url = validURL(value) {
            return url
        }
        return URL(string: "http://localhost:3000")!
    }

    private static func validURL(_ string: String) -> URL? {
        guard let url = URL(string: string), url.scheme != nil, url.host() != nil else { return nil }
        return url
    }
}
