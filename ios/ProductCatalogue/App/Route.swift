import Foundation

/// Every screen you can navigate to. Values only, so navigation stays testable
/// and deep links can be added later by building a [Route].
enum Route: Hashable {
    case category(ProductCategory)
    case product(id: String)
    case search(term: String)
}
