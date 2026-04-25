
import XCTest
@testable import ReceiptSnap

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - SUT + Mock
    var sut: LoginViewModel!
    var mockService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockService = MockAuthService()
        sut = LoginViewModel(authService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Validation tests

    func test_signIn_emptyEmail_setsEmailError() async {
        sut.email    = ""
        sut.password = "password"
        let result = await sut.signIn()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.emailError)
    }

    func test_signIn_invalidEmail_setsEmailError() async {
        sut.email    = "not-an-email"
        sut.password = "password"
        let result = await sut.signIn()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.emailError)
    }

    func test_signIn_emptyPassword_setsPasswordError() async {
        sut.email    = "test@example.com"
        sut.password = ""
        let result = await sut.signIn()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.passwordError)
    }

    // MARK: - Success tests

    func test_signIn_validCredentials_returnsUser() async {
        sut.email    = "demo@receiptsnap.com"
        sut.password = "Demo@1234"
        let result = await sut.signIn()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.email, "demo@receiptsnap.com")
    }

    func test_signIn_validCredentials_clearsErrors() async {
        sut.email    = "demo@receiptsnap.com"
        sut.password = "Demo@1234"
        _ = await sut.signIn()
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }

    func test_signIn_isLoading_falseAfterCompletion() async {
        sut.email    = "demo@receiptsnap.com"
        sut.password = "Demo@1234"
        _ = await sut.signIn()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Failure tests

    func test_signIn_wrongPassword_setsErrorMessage() async {
        sut.email    = "demo@receiptsnap.com"
        sut.password = "wrongpassword"
        let result = await sut.signIn()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_signIn_userNotFound_setsErrorMessage() async {
        sut.email    = "nobody@example.com"
        sut.password = "somepass"
        let result = await sut.signIn()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_signIn_serviceFailure_setsErrorMessage() async {
        mockService.shouldFailNextSignIn = true
        sut.email    = "demo@receiptsnap.com"
        sut.password = "Demo@1234"
        let result = await sut.signIn()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - UI state

    func test_isSignInEnabled_false_whenFieldsEmpty() {
        sut.email    = ""
        sut.password = ""
        XCTAssertFalse(sut.isSignInEnabled)
    }

    func test_isSignInEnabled_true_whenBothFilled() {
        sut.email    = "user@example.com"
        sut.password = "pass"
        XCTAssertTrue(sut.isSignInEnabled)
    }

    func test_clearErrors_removesAllErrors() async {
        sut.email    = ""
        sut.password = ""
        _ = await sut.signIn()  // triggers errors
        sut.clearErrors()
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.emailError)
        XCTAssertNil(sut.passwordError)
    }
}
