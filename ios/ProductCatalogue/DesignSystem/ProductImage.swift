import SwiftUI

struct ProductImage: View {
    let url: URL?
    let height: CGFloat

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            default:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(Theme.Spacing.s)
        .background(Theme.Colors.imageBackground)
        .accessibilityHidden(true)
    }
}
