import XCTest
@testable import ProductCatalogue

/// Repository tests against MockHTTPClient: right endpoint, right parameters,
/// correct DTO → model mapping, errors passed through untouched.
final class RemoteCatalogueRepositoryTests: XCTestCase {
    private var client: MockHTTPClient!
    private var repository: RemoteCatalogueRepository!

    override func setUp() {
        super.setUp()
        client = MockHTTPClient()
        repository = RemoteCatalogueRepository(client: client)
    }

    private static func productJSON(id: String, title: String = "Gaming Drive", slug: String = "electronics") -> String {
        """
        {"id":"\(id)","title":"\(title)","description":"Fast storage",
         "price":{"amount":114,"currency":"USD"},
         "category":{"slug":"\(slug)","name":"Electronics"},
         "imageUrl":"https://example.com/\(id).jpg",
         "rating":{"average":4.8,"count":400}}
        """
    }

    func testFeaturedProductsCallsFeaturedEndpointAndMapsProducts() async throws {
        client.respond(to: "api/products/featured", json: #"{"items":[\#(Self.productJSON(id: "12"))]}"#)

        let products = try await repository.featuredProducts()

        XCTAssertEqual(client.calls, [.init(method: "GET", path: "api/products/featured", query: [], body: nil)])
        XCTAssertEqual(products, [
            Product(
                id: "12",
                title: "Gaming Drive",
                description: "Fast storage",
                price: Money(amount: 114, currency: "USD"),
                category: ProductCategory(slug: "electronics", name: "Electronics"),
                imageURL: URL(string: "https://example.com/12.jpg"),
                rating: Rating(average: 4.8, count: 400)
            ),
        ])
    }

    func testCategoriesMapsSlugAndName() async throws {
        client.respond(to: "api/categories", json: #"{"items":[{"slug":"mens-clothing","name":"Men's Clothing"}]}"#)

        let categories = try await repository.categories()

        XCTAssertEqual(categories, [ProductCategory(slug: "mens-clothing", name: "Men's Clothing")])
    }

    func testCategoryPageUsesSlugInPathAndKeepsSectionsSeparate() async throws {
        client.respond(to: "api/categories/electronics", json: """
        {"category":{"slug":"electronics","name":"Electronics"},
         "topRated":[\(Self.productJSON(id: "11"))],
         "others":[\(Self.productJSON(id: "9")),\(Self.productJSON(id: "10"))]}
        """)

        let page = try await repository.categoryPage(slug: "electronics")

        XCTAssertEqual(client.calls.map(\.path), ["api/categories/electronics"])
        XCTAssertEqual(page.category, ProductCategory(slug: "electronics", name: "Electronics"))
        XCTAssertEqual(page.topRated.map(\.id), ["11"])
        XCTAssertEqual(page.others.map(\.id), ["9", "10"])
    }

    func testSearchSendsTermAsQueryParameter() async throws {
        client.respond(to: "api/products", json: #"{"items":[\#(Self.productJSON(id: "5", title: "Gold bracelet"))]}"#)

        let products = try await repository.searchProducts(term: "gold")

        XCTAssertEqual(client.calls, [
            .init(method: "GET", path: "api/products", query: [URLQueryItem(name: "search", value: "gold")], body: nil),
        ])
        XCTAssertEqual(products.map(\.title), ["Gold bracelet"])
    }

    func testProductUsesIdInPath() async throws {
        client.respond(to: "api/products/3", json: Self.productJSON(id: "3"))

        let product = try await repository.product(id: "3")

        XCTAssertEqual(client.calls.map(\.path), ["api/products/3"])
        XCTAssertEqual(product.id, "3")
    }

    func testClientErrorsArePassedThroughUnchanged() async {
        let notFound = APIError.server(status: 404, code: "not_found", message: "Product not found", fieldErrors: [:])
        client.fail("api/products/999", with: notFound)

        do {
            _ = try await repository.product(id: "999")
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, notFound)
        }
    }
}

final class RemoteEnquiryRepositoryTests: XCTestCase {
    func testSubmitPostsEnquiryAndReturnsReference() async throws {
        let client = MockHTTPClient()
        client.respond(to: "api/enquiries", json: #"{"reference":"abc-123"}"#)
        let repository = RemoteEnquiryRepository(client: client)

        let receipt = try await repository.submit(EnquiryRequest(
            productId: "4",
            name: "Asha Rao",
            email: "asha@example.com",
            phone: "+91 98765 43210",
            message: "Do you ship to Bengaluru?"
        ))

        XCTAssertEqual(receipt, EnquiryReceipt(reference: "abc-123"))
        XCTAssertEqual(client.calls.map(\.method), ["POST"])
        XCTAssertEqual(client.calls.first?.path, "api/enquiries")
        XCTAssertEqual(client.calls.first?.jsonBody, [
            "productId": "4",
            "name": "Asha Rao",
            "email": "asha@example.com",
            "phone": "+91 98765 43210",
            "message": "Do you ship to Bengaluru?",
        ])
    }

    func testOptionalFieldsAreOmittedWhenNil() async throws {
        let client = MockHTTPClient()
        client.respond(to: "api/enquiries", json: #"{"reference":"abc-123"}"#)
        let repository = RemoteEnquiryRepository(client: client)

        _ = try await repository.submit(EnquiryRequest(
            productId: "4", name: "Asha", email: "asha@example.com", phone: nil, message: nil
        ))

        XCTAssertEqual(client.calls.first?.jsonBody, ["productId": "4", "name": "Asha", "email": "asha@example.com"])
    }
}
