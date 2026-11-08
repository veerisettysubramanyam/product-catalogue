import Foundation

struct RemoteCatalogueRepository: CatalogueRepository {
    let client: any HTTPClient

    func featuredProducts() async throws -> [Product] {
        let response: ItemsDTO<ProductDTO> = try await client.get("api/products/featured")
        return response.items.map { $0.toDomain() }
    }

    func categories() async throws -> [ProductCategory] {
        let response: ItemsDTO<CategoryDTO> = try await client.get("api/categories")
        return response.items.map { $0.toDomain() }
    }

    func categoryPage(slug: String) async throws -> CategoryPage {
        let response: CategoryPageDTO = try await client.get("api/categories/\(slug)")
        return response.toDomain()
    }

    func searchProducts(term: String) async throws -> [Product] {
        let response: ItemsDTO<ProductDTO> = try await client.get(
            "api/products",
            query: [URLQueryItem(name: "search", value: term)]
        )
        return response.items.map { $0.toDomain() }
    }

    func product(id: String) async throws -> Product {
        let response: ProductDTO = try await client.get("api/products/\(id)")
        return response.toDomain()
    }
}

struct RemoteEnquiryRepository: EnquiryRepository {
    let client: any HTTPClient

    func submit(_ enquiry: EnquiryRequest) async throws -> EnquiryReceipt {
        let response: EnquiryReceiptDTO = try await client.post("api/enquiries", body: EnquiryRequestDTO(enquiry))
        return EnquiryReceipt(reference: response.reference)
    }
}
