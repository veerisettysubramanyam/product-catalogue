import Foundation
import Observation

@MainActor
@Observable
final class EnquiryViewModel: Identifiable {
    enum Field: String, CaseIterable, Hashable {
        case name, email, phone, message
    }

    enum State: Equatable {
        case editing
        case submitting
        case submitted(reference: String)
    }

    static let maxNameLength = 100
    static let maxMessageLength = 2000

    let product: Product

    var name = ""
    var email = ""
    var phone = ""
    var message = ""

    private(set) var state: State = .editing
    private(set) var fieldErrors: [Field: String] = [:]
    /// Error not tied to a single field (network down, server error).
    private(set) var submitError: String?

    var isSubmitting: Bool { state == .submitting }

    var isSubmitted: Bool {
        if case .submitted = state { return true }
        return false
    }

    private let repository: any EnquiryRepository

    init(product: Product, repository: any EnquiryRepository) {
        self.product = product
        self.repository = repository
    }

    /// Mirrors the backend rules so users get instant feedback. The backend stays the source of truth.
    @discardableResult
    func validate() -> Bool {
        var errors: [Field: String] = [:]

        let name = trimmed(self.name)
        if name.isEmpty {
            errors[.name] = "Please enter your name."
        } else if name.count > Self.maxNameLength {
            errors[.name] = "Name must be \(Self.maxNameLength) characters or fewer."
        }

        let email = trimmed(self.email)
        if email.isEmpty {
            errors[.email] = "Please enter your email."
        } else if email.range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) == nil {
            errors[.email] = "Enter a valid email address."
        }

        let phone = trimmed(self.phone)
        if !phone.isEmpty, phone.range(of: #"^[0-9+()\-.\s]{6,30}$"#, options: .regularExpression) == nil {
            errors[.phone] = "Enter a valid phone number."
        }

        if trimmed(message).count > Self.maxMessageLength {
            errors[.message] = "Message must be \(Self.maxMessageLength) characters or fewer."
        }

        fieldErrors = errors
        return errors.isEmpty
    }

    func submit() async {
        guard state == .editing else { return }
        submitError = nil
        guard validate() else { return }

        state = .submitting
        let request = EnquiryRequest(
            productId: product.id,
            name: trimmed(name),
            email: trimmed(email),
            phone: nilIfEmpty(phone),
            message: nilIfEmpty(message)
        )

        do {
            let receipt = try await repository.submit(request)
            state = .submitted(reference: receipt.reference)
        } catch let APIError.server(_, _, message, serverFieldErrors) where !serverFieldErrors.isEmpty {
            state = .editing
            fieldErrors = Dictionary(
                serverFieldErrors.compactMap { key, value in Field(rawValue: key).map { ($0, value) } },
                uniquingKeysWith: { first, _ in first }
            )
            // If the server flagged a field we don't show (e.g. productId), surface its message at form level.
            if fieldErrors.isEmpty { submitError = message ?? "Please check your details and try again." }
        } catch {
            state = .editing
            submitError = ErrorMessage.from(error)
        }
    }

    private func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nilIfEmpty(_ value: String) -> String? {
        let value = trimmed(value)
        return value.isEmpty ? nil : value
    }
}
