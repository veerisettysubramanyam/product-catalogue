import SwiftUI

struct EnquiryFormView: View {
    @Bindable var viewModel: EnquiryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: EnquiryViewModel.Field?

    var body: some View {
        NavigationStack {
            Group {
                if case .submitted(let reference) = viewModel.state {
                    ThankYouView(productTitle: viewModel.product.title, reference: reference) {
                        dismiss()
                    }
                } else {
                    form
                }
            }
            .navigationTitle("Enquire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.isSubmitted {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .disabled(viewModel.isSubmitting)
                    }
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isSubmitting)
    }

    private var form: some View {
        Form {
            Section {
                Text(viewModel.product.title)
                    .font(.subheadline)
            } header: {
                Text("Product")
            }

            Section {
                field(.name) {
                    TextField("Name", text: $viewModel.name)
                        .textContentType(.name)
                        .submitLabel(.next)
                }
                field(.email) {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                field(.phone) {
                    TextField("Phone (optional)", text: $viewModel.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                field(.message) {
                    TextField("Message (optional)", text: $viewModel.message, axis: .vertical)
                        .lineLimit(3...6)
                }
            } header: {
                Text("Your details")
            } footer: {
                Text("Our sales team will reply to your email.")
            }

            if let submitError = viewModel.submitError {
                Section {
                    Label(submitError, systemImage: "exclamationmark.circle")
                        .foregroundStyle(Theme.Colors.error)
                }
            }

            Section {
                Button {
                    focusedField = nil
                    Task { await viewModel.submit() }
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Send enquiry").bold()
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.isSubmitting)
                .accessibilityIdentifier("submitEnquiryButton")
            }
        }
        .disabled(viewModel.isSubmitting)
        .onSubmit {
            switch focusedField {
            case .name: focusedField = .email
            case .email: focusedField = .phone
            default: focusedField = nil
            }
        }
    }

    @ViewBuilder
    private func field<Input: View>(_ field: EnquiryViewModel.Field, @ViewBuilder input: () -> Input) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            input()
                .focused($focusedField, equals: field)
            if let error = viewModel.fieldErrors[field] {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Theme.Colors.error)
            }
        }
    }
}

private struct ThankYouView: View {
    let productTitle: String
    let reference: String
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Thank you!")
                .font(.title.bold())
            Text("We've received your enquiry about \(productTitle). Our sales team will be in touch soon.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.secondaryText)
            Text("Reference: \(reference.prefix(8).uppercased())")
                .font(.footnote.monospaced())
                .foregroundStyle(Theme.Colors.secondaryText)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(Theme.Spacing.xl)
        .accessibilityIdentifier("thankYouView")
    }
}
