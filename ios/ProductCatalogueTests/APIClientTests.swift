import XCTest
@testable import ProductCatalogue

/// Exercises the real APIClient + RemoteRepositories against canned HTTP responses.
final class APIClientTests: XCTestCase {
    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(baseURL: URL(string: "http://localhost:3000")!, session: URLSession(configuration: configuration))
    }

    func testDecodesProductsIntoDomainModels() async throws {
        StubURLProtocol.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/products/featured")
            return (200, """
            {"items":[{"id":"3","title":"Mens Cotton Jacket","description":"Great","price":{"amount":55.99,"currency":"USD"},
            "category":{"slug":"mens-clothing","name":"Men's Clothing"},"imageUrl":"https://example.com/3.jpg",
            "rating":{"average":4.7,"count":500}}]}
            """)
        }
        let repository = RemoteCatalogueRepository(client: makeClient())

        let products = try await repository.featuredProducts()

        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.id, "3")
        XCTAssertEqual(products.first?.price, Money(amount: Decimal(string: "55.99")!, currency: "USD"))
        XCTAssertEqual(products.first?.category, ProductCategory(slug: "mens-clothing", name: "Men's Clothing"))
    }

    func testSendsSearchTermAsQueryParameter() async throws {
        StubURLProtocol.handler = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            XCTAssertEqual(components?.path, "/api/products")
            XCTAssertEqual(components?.queryItems, [URLQueryItem(name: "search", value: "gold ring")])
            return (200, #"{"items":[]}"#)
        }

        let products = try await RemoteCatalogueRepository(client: makeClient()).searchProducts(term: "gold ring")

        XCTAssertEqual(products, [])
    }

    func testMapsValidationErrorsToFieldErrors() async {
        StubURLProtocol.handler = { _ in
            (400, """
            {"error":{"code":"validation_failed","message":"Request is invalid",
            "details":[{"field":"email","message":"Enter a valid email address"}]}}
            """)
        }
        let repository = RemoteEnquiryRepository(client: makeClient())
        let request = EnquiryRequest(productId: "1", name: "A", email: "bad", phone: nil, message: nil)

        do {
            _ = try await repository.submit(request)
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .server(
                status: 400,
                code: "validation_failed",
                message: "Request is invalid",
                fieldErrors: ["email": "Enter a valid email address"]
            ))
        }
    }

    func testServerErrorWithoutBodyStillMapsToAPIError() async {
        StubURLProtocol.handler = { _ in (502, "") }

        do {
            _ = try await RemoteCatalogueRepository(client: makeClient()).categories()
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .server(status: 502, code: nil, message: nil, fieldErrors: [:]))
        }
    }

    func testUnexpectedJSONIsADecodingError() async {
        StubURLProtocol.handler = { _ in (200, #"{"unexpected":true}"#) }

        do {
            _ = try await RemoteCatalogueRepository(client: makeClient()).categories()
            XCTFail("expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .decoding)
        }
    }
}

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, String))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, body) = handler(request)
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
