import Foundation

enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
extension LoadState: Sendable where Value: Sendable {}
