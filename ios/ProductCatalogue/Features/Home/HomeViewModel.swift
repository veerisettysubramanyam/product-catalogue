import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    struct Content: Equatable {
        let featured: [Product]
        let categories: [ProductCategory]
    }

    private(set) var state: LoadState<Content> = .idle
    var searchText = ""

    var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSearch: Bool {
        !trimmedSearchText.isEmpty
    }

    private let repository: any CatalogueRepository

    init(repository: any CatalogueRepository) {
        self.repository = repository
    }

    func load() async {
        // Keep showing existing content during pull-to-refresh.
        if state.value == nil { state = .loading }

        let repository = self.repository
        do {
            async let featured = repository.featuredProducts()
            async let categories = repository.categories()
            state = .loaded(Content(featured: try await featured, categories: try await categories))
        } catch is CancellationError {
            if state.value == nil { state = .idle }
        } catch {
            state = .failed(ErrorMessage.from(error))
        }
    }
}
