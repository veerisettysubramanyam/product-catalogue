import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    @State private var enquiry: EnquiryViewModel?
    private let makeEnquiryViewModel: (Product) -> EnquiryViewModel

    init(viewModel: ProductDetailViewModel, makeEnquiryViewModel: @escaping (Product) -> EnquiryViewModel) {
        _viewModel = State(initialValue: viewModel)
        self.makeEnquiryViewModel = makeEnquiryViewModel
    }

    var body: some View {
        LoadStateView(state: viewModel.state, retry: viewModel.load) { product in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    ProductImage(url: product.imageURL, height: Theme.Layout.detailImageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))

                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(product.category.name.uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.Colors.secondaryText)
                        Text(product.title)
                            .font(Theme.Fonts.detailTitle)
                        HStack {
                            Text(product.price.formatted)
                                .font(Theme.Fonts.price)
                            Spacer()
                            RatingView(rating: product.rating)
                        }
                    }

                    Text(product.description)
                        .font(.body)
                }
                .padding(Theme.Spacing.l)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    enquiry = makeEnquiryViewModel(product)
                } label: {
                    Text("Enquire")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(Theme.Spacing.l)
                .background(.bar)
                .accessibilityIdentifier("enquireButton")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.state == .idle { await viewModel.load() }
        }
        .sheet(item: $enquiry) { enquiryViewModel in
            EnquiryFormView(viewModel: enquiryViewModel)
        }
    }
}
