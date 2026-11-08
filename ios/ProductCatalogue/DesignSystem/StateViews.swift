import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, minHeight: 200)
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try again") {
                Task { await retry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Fonts.sectionTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Renders the right view for each `LoadState`, so every screen gets loading,
/// error-with-retry and content handling the same way.
struct LoadStateView<Value, Content: View>: View {
    let state: LoadState<Value>
    let retry: () async -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            LoadingView()
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}
