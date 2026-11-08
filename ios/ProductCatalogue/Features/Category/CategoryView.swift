import SwiftUI

struct CategoryView: View {
    @State private var viewModel: CategoryViewModel

    init(viewModel: CategoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            LoadStateView(state: viewModel.state, retry: viewModel.load) { page in
                if page.topRated.isEmpty && page.others.isEmpty {
                    EmptyStateView(
                        title: "Nothing here yet",
                        systemImage: "shippingbox",
                        message: "There are no products in \(page.category.name)."
                    )
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        if !page.topRated.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                SectionHeader(title: "Top rated")
                                ProductGrid(products: page.topRated)
                            }
                        }
                        if !page.others.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                                SectionHeader(title: "More in \(page.category.name)")
                                ProductGrid(products: page.others)
                            }
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .navigationTitle(viewModel.category.name)
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
        .refreshable { await viewModel.load() }
    }
}
