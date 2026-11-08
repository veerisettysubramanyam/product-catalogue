import SwiftUI

struct RatingView: View {
    let rating: Rating

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "star.fill")
                .foregroundStyle(Theme.Colors.rating)
            Text(rating.average, format: .number.precision(.fractionLength(1)))
            Text("(\(rating.count))")
                .foregroundStyle(Theme.Colors.secondaryText)
        }
        .font(.caption)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(rating.average.formatted(.number.precision(.fractionLength(1)))) out of 5 from \(rating.count) reviews")
    }
}
