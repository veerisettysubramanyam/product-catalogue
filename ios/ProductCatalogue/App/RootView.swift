import SwiftUI

struct RootView: View {
    private let dependencies: AppDependencies
    @State private var path: [Route] = []
    @State private var homeViewModel: HomeViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _homeViewModel = State(initialValue: HomeViewModel(repository: dependencies.catalogue))
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(viewModel: homeViewModel) { term in
                path.append(.search(term: term))
            }
            .navigationDestination(for: Route.self, destination: destination)
        }
        .tint(Theme.Colors.accent)
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .category(let category):
            CategoryView(viewModel: CategoryViewModel(category: category, repository: dependencies.catalogue))
        case .product(let id):
            ProductDetailView(
                viewModel: ProductDetailViewModel(productId: id, repository: dependencies.catalogue),
                makeEnquiryViewModel: { product in
                    EnquiryViewModel(product: product, repository: dependencies.enquiries)
                }
            )
        case .search(let term):
            SearchResultsView(viewModel: SearchViewModel(term: term, repository: dependencies.catalogue))
        }
    }
}
