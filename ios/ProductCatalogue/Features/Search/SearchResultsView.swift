import SwiftUI

struct SearchResultsView: View {
    @State private var viewModel: SearchViewModel

    init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LoadStateView(state: viewModel.state, retry: viewModel.load) { products in
                if products.isEmpty {
                    EmptyStateView(
                        title: "No results",
                        systemImage: "magnifyingglass",
                        message: "No products match “\(viewModel.term)”. Try a different word."
                    )
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text(products.count == 1 ? "1 result" : "\(products.count) results")
                            .font(.subheadline)
                            .foregroundStyle(Theme.Colors.secondaryText)
                        ProductGrid(products: products)
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .navigationTitle("“\(viewModel.term)”")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
    }
}
