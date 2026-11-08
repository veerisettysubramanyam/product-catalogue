import XCTest
@testable import ProductCatalogue

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testLoadShowsFeaturedProductsAndCategories() async {
        let repository = MockCatalogueRepository()
        repository.featuredResult = .success([Fixtures.product("1"), Fixtures.product("2")])
        repository.categoriesResult = .success([Fixtures.electronics, Fixtures.jewelery])
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.featured.map(\.id), ["1", "2"])
        XCTAssertEqual(viewModel.state.value?.categories, [Fixtures.electronics, Fixtures.jewelery])
    }

    func testLoadFailureShowsUserFacingMessage() async {
        let repository = MockCatalogueRepository()
        repository.featuredResult = .failure(APIError.network)
        let viewModel = HomeViewModel(repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed(APIError.network.userMessage))
    }

    func testRetryAfterFailureRecovers() async {
        let repository = MockCatalogueRepository()
        repository.featuredResult = .failure(APIError.network)
        let viewModel = HomeViewModel(repository: repository)
        await viewModel.load()

        repository.featuredResult = .success([Fixtures.product("1")])
        await viewModel.load()

        XCTAssertEqual(viewModel.state.value?.featured.map(\.id), ["1"])
    }

    func testSearchIsOnlyEnabledForNonBlankText() {
        let viewModel = HomeViewModel(repository: MockCatalogueRepository())

        viewModel.searchText = "   "
        XCTAssertFalse(viewModel.canSearch)

        viewModel.searchText = "  jacket "
        XCTAssertTrue(viewModel.canSearch)
        XCTAssertEqual(viewModel.trimmedSearchText, "jacket")
    }
}

@MainActor
final class CategoryViewModelTests: XCTestCase {
    func testLoadsPageForTheCategory() async {
        let repository = MockCatalogueRepository()
        let page = CategoryPage(
            category: Fixtures.electronics,
            topRated: [Fixtures.product("1")],
            others: [Fixtures.product("2"), Fixtures.product("3")]
        )
        repository.categoryPageResult = .success(page)
        let viewModel = CategoryViewModel(category: Fixtures.electronics, repository: repository)

        await viewModel.load()

        XCTAssertEqual(repository.requestedSlugs, ["electronics"])
        XCTAssertEqual(viewModel.state, .loaded(page))
    }

    func testServerMessageIsShownOnFailure() async {
        let repository = MockCatalogueRepository()
        repository.categoryPageResult = .failure(
            APIError.server(status: 404, code: "not_found", message: "Category not found", fieldErrors: [:])
        )
        let viewModel = CategoryViewModel(category: Fixtures.electronics, repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .failed("Category not found"))
    }
}

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testSearchesForTheTerm() async {
        let repository = MockCatalogueRepository()
        repository.searchResult = .success([Fixtures.product("7", title: "Gold ring")])
        let viewModel = SearchViewModel(term: "gold", repository: repository)

        await viewModel.load()

        XCTAssertEqual(repository.searchedTerms, ["gold"])
        XCTAssertEqual(viewModel.state.value?.map(\.title), ["Gold ring"])
    }

    func testNoMatchesIsAnEmptyListNotAnError() async {
        let repository = MockCatalogueRepository()
        repository.searchResult = .success([])
        let viewModel = SearchViewModel(term: "zzz", repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([]))
    }
}

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    func testLoadsTheProductById() async {
        let repository = MockCatalogueRepository()
        let product = Fixtures.product("42")
        repository.productResult = .success(product)
        let viewModel = ProductDetailViewModel(productId: "42", repository: repository)

        await viewModel.load()

        XCTAssertEqual(repository.requestedProductIds, ["42"])
        XCTAssertEqual(viewModel.state, .loaded(product))
    }

    func testCancellationDoesNotShowAnError() async {
        let repository = MockCatalogueRepository()
        repository.productResult = .failure(CancellationError())
        let viewModel = ProductDetailViewModel(productId: "42", repository: repository)

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .idle)
    }
}
