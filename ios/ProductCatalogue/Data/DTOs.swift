import Foundation

/// Wire formats for our backend API. Mapped to domain models with `toDomain()`.

struct ItemsDTO<Item: Decodable>: Decodable {
    let items: [Item]
}

struct MoneyDTO: Decodable {
    let amount: Decimal
    let currency: String
}

struct CategoryDTO: Decodable {
    let slug: String
    let name: String

    func toDomain() -> ProductCategory {
        ProductCategory(slug: slug, name: name)
    }
}

struct RatingDTO: Decodable {
    let average: Double
    let count: Int
}

struct ProductDTO: Decodable {
    let id: String
    let title: String
    let description: String
    let price: MoneyDTO
    let category: CategoryDTO
    let imageUrl: String
    let rating: RatingDTO

    func toDomain() -> Product {
        Product(
            id: id,
            title: title,
            description: description,
            price: Money(amount: price.amount, currency: price.currency),
            category: category.toDomain(),
            imageURL: URL(string: imageUrl),
            rating: Rating(average: rating.average, count: rating.count)
        )
    }
}

struct CategoryPageDTO: Decodable {
    let category: CategoryDTO
    let topRated: [ProductDTO]
    let others: [ProductDTO]

    func toDomain() -> CategoryPage {
        CategoryPage(
            category: category.toDomain(),
            topRated: topRated.map { $0.toDomain() },
            others: others.map { $0.toDomain() }
        )
    }
}

struct EnquiryRequestDTO: Encodable {
    let productId: String
    let name: String
    let email: String
    let phone: String?
    let message: String?

    init(_ enquiry: EnquiryRequest) {
        productId = enquiry.productId
        name = enquiry.name
        email = enquiry.email
        phone = enquiry.phone
        message = enquiry.message
    }
}

struct EnquiryReceiptDTO: Decodable {
    let reference: String
}

struct ErrorEnvelopeDTO: Decodable {
    struct FieldError: Decodable {
        let field: String
        let message: String
    }

    struct Body: Decodable {
        let code: String
        let message: String
        let details: [FieldError]?
    }

    let error: Body
}
