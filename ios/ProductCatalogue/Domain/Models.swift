import Foundation

/// App-side models. Views and view models only use these, never the API DTOs,
/// so a backend contract change is absorbed in the Data layer.

struct Money: Hashable, Sendable {
    let amount: Decimal
    let currency: String

    var formatted: String {
        amount.formatted(.currency(code: currency))
    }
}

struct ProductCategory: Hashable, Identifiable, Sendable {
    let slug: String
    let name: String

    var id: String { slug }
}

struct Rating: Hashable, Sendable {
    let average: Double
    let count: Int
}

struct Product: Hashable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let price: Money
    let category: ProductCategory
    let imageURL: URL?
    let rating: Rating
}

struct CategoryPage: Equatable, Sendable {
    let category: ProductCategory
    let topRated: [Product]
    let others: [Product]
}

struct EnquiryRequest: Equatable, Sendable {
    let productId: String
    let name: String
    let email: String
    let phone: String?
    let message: String?
}

struct EnquiryReceipt: Equatable, Sendable {
    let reference: String
}
