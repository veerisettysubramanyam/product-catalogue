import SwiftUI

/// Search field with an explicit Search button (per the acceptance criteria),
/// plus the keyboard's search key.
struct SearchBar: View {
    @Binding var text: String
    let isEnabled: Bool
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.Colors.secondaryText)
                TextField("Search products", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { if isEnabled { onSubmit() } }
                    .accessibilityIdentifier("searchField")
            }
            .padding(Theme.Spacing.s + 2)
            .background(Theme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control))

            Button("Search", action: onSubmit)
                .buttonStyle(.borderedProminent)
                .disabled(!isEnabled)
                .accessibilityIdentifier("searchButton")
        }
    }
}
