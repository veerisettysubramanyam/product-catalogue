import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    let term: String
    private(set) var state: LoadState<[Product]> = .idle

    private let repository: any CatalogueRepository

    init(term: String, repository: any CatalogueRepository) {
        self.term = term
        self.repository = repository
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await repository.searchProducts(term: term))
        } catch is CancellationError {
            if state.value == nil { state = .idle }
        } catch {
            state = .failed(ErrorMessage.from(error))
        }
    }
}
