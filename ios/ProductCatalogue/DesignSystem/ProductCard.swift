import SwiftUI

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            ProductImage(url: product.imageURL, height: Theme.Layout.cardImageHeight)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))

            Text(product.title)
                .font(Theme.Fonts.cardTitle)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            HStack {
                Text(product.price.formatted)
                    .font(Theme.Fonts.price)
                Spacer()
                RatingView(rating: product.rating)
            }
        }
        .padding(Theme.Spacing.s)
        .background(Theme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .combine)
    }
}

/// A grid of product tiles. Tapping a tile navigates to that product's detail page.
struct ProductGrid: View {
    let products: [Product]

    var body: some View {
        LazyVGrid(columns: Theme.Layout.gridColumns, spacing: Theme.Spacing.m) {
            ForEach(products) { product in
                NavigationLink(value: Route.product(id: product.id)) {
                    ProductCard(product: product)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
