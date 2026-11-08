import SwiftUI

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    let onSearch: (String) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                SearchBar(text: $viewModel.searchText, isEnabled: viewModel.canSearch) {
                    onSearch(viewModel.trimmedSearchText)
                }

                LoadStateView(state: viewModel.state, retry: viewModel.load) { content in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        featuredSection(content.featured)
                        categoriesSection(content.categories)
                    }
                }
            }
            .padding(Theme.Spacing.l)
        }
        .navigationTitle("Catalogue")
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private func featuredSection(_ products: [Product]) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "Top rated")
            if products.isEmpty {
                EmptyStateView(title: "No featured products", systemImage: "star", message: "Check back soon.")
            } else {
                ProductGrid(products: products)
            }
        }
    }

    @ViewBuilder
    private func categoriesSection(_ categories: [ProductCategory]) -> some View {
        if !categories.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                SectionHeader(title: "Shop by category")
                ForEach(categories) { category in
                    NavigationLink(value: Route.category(category)) {
                        HStack {
                            Text(category.name)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding(Theme.Spacing.m)
                        .background(Theme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
