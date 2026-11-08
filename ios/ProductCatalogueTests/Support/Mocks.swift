import Foundation
@testable import ProductCatalogue

enum Fixtures {
    static let electronics = ProductCategory(slug: "electronics", name: "Electronics")
    static let jewelery = ProductCategory(slug: "jewelery", name: "Jewelery")

    static func product(_ id: String, title: String? = nil, category: ProductCategory = electronics) -> Product {
        Product(
            id: id,
            title: title ?? "Product \(id)",
            description: "Description \(id)",
            price: Money(amount: 10, currency: "USD"),
            category: category,
            imageURL: URL(string: "https://example.com/\(id).jpg"),
            rating: Rating(average: 4, count: 10)
        )
    }
}

struct TestError: Error {}

/// Configurable in-memory repository. Each property is the result the next call returns.
final class MockCatalogueRepository: CatalogueRepository, @unchecked Sendable {
    var featuredResult: Result<[Product], Error> = .success([])
    var categoriesResult: Result<[ProductCategory], Error> = .success([])
    var categoryPageResult: Result<CategoryPage, Error> = .failure(TestError())
    var searchResult: Result<[Product], Error> = .success([])
    var productResult: Result<Product, Error> = .failure(TestError())

    private(set) var searchedTerms: [String] = []
    private(set) var requestedSlugs: [String] = []
    private(set) var requestedProductIds: [String] = []

    func featuredProducts() async throws -> [Product] { try featuredResult.get() }
    func categories() async throws -> [ProductCategory] { try categoriesResult.get() }

    func categoryPage(slug: String) async throws -> CategoryPage {
        requestedSlugs.append(slug)
        return try categoryPageResult.get()
    }

    func searchProducts(term: String) async throws -> [Product] {
        searchedTerms.append(term)
        return try searchResult.get()
    }

    func product(id: String) async throws -> Product {
        requestedProductIds.append(id)
        return try productResult.get()
    }
}

final class MockEnquiryRepository: EnquiryRepository, @unchecked Sendable {
    var result: Result<EnquiryReceipt, Error> = .success(EnquiryReceipt(reference: "ref-123"))
    private(set) var submitted: [EnquiryRequest] = []

    func submit(_ enquiry: EnquiryRequest) async throws -> EnquiryReceipt {
        submitted.append(enquiry)
        return try result.get()
    }
}
