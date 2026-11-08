import Foundation

/// Composition root: the one place that picks concrete implementations.
struct AppDependencies: Sendable {
    let catalogue: any CatalogueRepository
    let enquiries: any EnquiryRepository

    static func live(baseURL: URL = AppConfig.apiBaseURL) -> AppDependencies {
        let client = APIClient(baseURL: baseURL)
        return AppDependencies(
            catalogue: RemoteCatalogueRepository(client: client),
            enquiries: RemoteEnquiryRepository(client: client)
        )
    }
}
