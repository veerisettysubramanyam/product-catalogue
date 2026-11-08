import Foundation
import Observation

@MainActor
@Observable
final class CategoryViewModel {
    let category: ProductCategory
    private(set) var state: LoadState<CategoryPage> = .idle

    private let repository: any CatalogueRepository

    init(category: ProductCategory, repository: any CatalogueRepository) {
        self.category = category
        self.repository = repository
    }

    func load() async {
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await repository.categoryPage(slug: category.slug))
        } catch is CancellationError {
            if state.value == nil { state = .idle }
        } catch {
            state = .failed(ErrorMessage.from(error))
        }
    }
}
