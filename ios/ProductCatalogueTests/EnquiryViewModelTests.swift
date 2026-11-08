import XCTest
@testable import ProductCatalogue

@MainActor
final class EnquiryViewModelTests: XCTestCase {
    private var repository: MockEnquiryRepository!
    private var viewModel: EnquiryViewModel!

    override func setUp() async throws {
        repository = MockEnquiryRepository()
        viewModel = EnquiryViewModel(product: Fixtures.product("4"), repository: repository)
    }

    private func fillValidForm() {
        viewModel.name = "  Asha Rao "
        viewModel.email = "asha@example.com"
        viewModel.phone = ""
        viewModel.message = "Do you ship to Bengaluru?"
    }

    func testSuccessfulSubmitShowsThankYouAndSendsTrimmedData() async {
        fillValidForm()

        await viewModel.submit()

        XCTAssertEqual(viewModel.state, .submitted(reference: "ref-123"))
        XCTAssertTrue(viewModel.isSubmitted)
        XCTAssertEqual(repository.submitted, [
            EnquiryRequest(
                productId: "4",
                name: "Asha Rao",
                email: "asha@example.com",
                phone: nil,
                message: "Do you ship to Bengaluru?"
            ),
        ])
    }

    func testEmptyFormShowsRequiredErrorsAndDoesNotSubmit() async {
        await viewModel.submit()

        XCTAssertEqual(viewModel.state, .editing)
        XCTAssertNotNil(viewModel.fieldErrors[.name])
        XCTAssertNotNil(viewModel.fieldErrors[.email])
        XCTAssertNil(viewModel.fieldErrors[.phone], "phone is optional")
        XCTAssertTrue(repository.submitted.isEmpty)
    }

    func testInvalidEmailAndPhoneAreRejected() async {
        fillValidForm()
        viewModel.email = "asha-at-example"
        viewModel.phone = "call me"

        await viewModel.submit()

        XCTAssertEqual(viewModel.fieldErrors[.email], "Enter a valid email address.")
        XCTAssertEqual(viewModel.fieldErrors[.phone], "Enter a valid phone number.")
        XCTAssertTrue(repository.submitted.isEmpty)
    }

    func testOverlongMessageIsRejected() async {
        fillValidForm()
        viewModel.message = String(repeating: "x", count: EnquiryViewModel.maxMessageLength + 1)

        await viewModel.submit()

        XCTAssertNotNil(viewModel.fieldErrors[.message])
        XCTAssertTrue(repository.submitted.isEmpty)
    }

    func testServerFieldErrorsAreShownAgainstTheirFields() async {
        fillValidForm()
        repository.result = .failure(APIError.server(
            status: 400,
            code: "validation_failed",
            message: "Request is invalid",
            fieldErrors: ["email": "Enter a valid email address"]
        ))

        await viewModel.submit()

        XCTAssertEqual(viewModel.state, .editing)
        XCTAssertEqual(viewModel.fieldErrors[.email], "Enter a valid email address")
        XCTAssertNil(viewModel.submitError)
    }

    func testNetworkFailureKeepsTheFormAndShowsAnError() async {
        fillValidForm()
        repository.result = .failure(APIError.network)

        await viewModel.submit()

        XCTAssertEqual(viewModel.state, .editing)
        XCTAssertEqual(viewModel.submitError, APIError.network.userMessage)
        XCTAssertEqual(viewModel.name, "  Asha Rao ", "user input must not be lost")
    }

    func testFixingErrorsAndResubmittingClearsThem() async {
        await viewModel.submit()
        XCTAssertFalse(viewModel.fieldErrors.isEmpty)

        fillValidForm()
        await viewModel.submit()

        XCTAssertTrue(viewModel.fieldErrors.isEmpty)
        XCTAssertTrue(viewModel.isSubmitted)
    }
}
