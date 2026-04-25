
import XCTest
@testable import ReceiptSnap

@MainActor
final class SignUpViewModelTests: XCTestCase {

    var sut: SignUpViewModel!
    var mockService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockService = MockAuthService()
        sut = SignUpViewModel(authService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Validation

    func test_signUp_emptyName_setsNameError() async {
        fillValidForm(); sut.fullName = ""
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.nameError)
    }

    func test_signUp_shortName_setsNameError() async {
        fillValidForm(); sut.fullName = "A"
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.nameError)
    }

    func test_signUp_invalidEmail_setsEmailError() async {
        fillValidForm(); sut.email = "bad-email"
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.emailError)
    }

    func test_signUp_shortPassword_setsPasswordError() async {
        fillValidForm(); sut.password = "abc"; sut.confirmPassword = "abc"
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.passwordError)
    }

    func test_signUp_passwordMismatch_setsConfirmError() async {
        fillValidForm(); sut.confirmPassword = "different"
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.confirmPasswordError)
    }

    func test_signUp_termsNotAccepted_setsErrorMessage() async {
        fillValidForm(); sut.agreedToTerms = false
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Success

    func test_signUp_validForm_returnsUser() async {
        fillValidForm()
        let result = await sut.signUp()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.email, sut.email.lowercased())
    }

    func test_signUp_validForm_clearsErrors() async {
        fillValidForm()
        _ = await sut.signUp()
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.nameError)
        XCTAssertNil(sut.emailError)
    }

    // MARK: - Service failure

    func test_signUp_duplicateEmail_setsErrorMessage() async {
        fillValidForm()
        _ = await sut.signUp()   // first signup succeeds
        fillValidForm()          // same email again
        let result = await sut.signUp()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Password strength

    func test_hasMinLength_falseWhenShort() {
        sut.password = "abc"
        XCTAssertFalse(sut.hasMinLength)
    }

    func test_hasMinLength_trueWhenLongEnough() {
        sut.password = "abcdefgh"
        XCTAssertTrue(sut.hasMinLength)
    }

    func test_hasSymbolOrNumber_trueWithDigit() {
        sut.password = "abc12345"
        XCTAssertTrue(sut.hasSymbolOrNumber)
    }

    func test_hasSymbolOrNumber_falseWithLettersOnly() {
        sut.password = "abcdefgh"
        XCTAssertFalse(sut.hasSymbolOrNumber)
    }

    func test_passwordsMatch_trueWhenEqual() {
        sut.password = "Pass@1234"; sut.confirmPassword = "Pass@1234"
        XCTAssertTrue(sut.passwordsMatch)
    }

    // MARK: - isSignUpEnabled

    func test_isSignUpEnabled_false_whenTermsUnchecked() {
        fillValidForm(); sut.agreedToTerms = false
        XCTAssertFalse(sut.isSignUpEnabled)
    }

    func test_isSignUpEnabled_true_whenAllFilled() {
        fillValidForm()
        XCTAssertTrue(sut.isSignUpEnabled)
    }

    // MARK: - Helpers
    private func fillValidForm() {
        sut.fullName        = "Test User"
        sut.email           = "newuser@example.com"
        sut.password        = "Password@123"
        sut.confirmPassword = "Password@123"
        sut.agreedToTerms   = true
    }
}
