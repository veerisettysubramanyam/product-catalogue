import Foundation
import Observation

@MainActor
@Observable
final class ProductDetailViewModel {
    let productId: String
    private(set) var state: LoadState<Product> = .idle

    private let repository: any CatalogueRepository

    init(productId: String, repository: any CatalogueRepository) {
        self.productId = productId
        self.repository = repository
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await repository.product(id: productId))
        } catch is CancellationError {
            if state.value == nil { state = .idle }
        } catch {
            state = .failed(ErrorMessage.from(error))
        }
    }
}
