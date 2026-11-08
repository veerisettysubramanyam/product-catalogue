import Foundation

/// What the UI needs from "somewhere that has products". The live implementation
/// talks to our backend; tests and previews use in-memory mocks.
protocol CatalogueRepository: Sendable {
    func featuredProducts() async throws -> [Product]
    func categories() async throws -> [ProductCategory]
    func categoryPage(slug: String) async throws -> CategoryPage
    func searchProducts(term: String) async throws -> [Product]
    func product(id: String) async throws -> Product
}

protocol EnquiryRepository: Sendable {
    func submit(_ enquiry: EnquiryRequest) async throws -> EnquiryReceipt
}
