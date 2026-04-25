
import XCTest
@testable import ReceiptSnap

@MainActor
final class ForgotPasswordViewModelTests: XCTestCase {

    var sut: ForgotPasswordViewModel!
    var mockService: MockAuthService!

    override func setUp() {
        super.setUp()
        mockService = MockAuthService()
        sut = ForgotPasswordViewModel(authService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Step 1: sendVerificationCode

    func test_sendCode_emptyEmail_returnsFalse() async {
        sut.email = ""
        let result = await sut.sendVerificationCode()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.emailError)
    }

    func test_sendCode_invalidEmail_returnsFalse() async {
        sut.email = "not-valid"
        let result = await sut.sendVerificationCode()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.emailError)
    }

    func test_sendCode_validRegisteredEmail_returnsTrue() async {
        sut.email = "demo@receiptsnap.com"
        let result = await sut.sendVerificationCode()
        XCTAssertTrue(result)
    }

    func test_sendCode_unknownEmail_returnsFalse() async {
        sut.email = "ghost@example.com"
        let result = await sut.sendVerificationCode()
        XCTAssertFalse(result)
    }

    func test_sendCode_isLoading_falseAfterCompletion() async {
        sut.email = "demo@receiptsnap.com"
        _ = await sut.sendVerificationCode()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Step 2: verifyOTPCode

    func test_verifyOTP_lessThan6Digits_returnsFalse() async {
        sut.otpCode = "123"
        let result = await sut.verifyOTPCode()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.otpError)
    }

    func test_verifyOTP_valid6Digits_returnsTrue() async {
        sut.otpCode = "123456"
        let result = await sut.verifyOTPCode()
        XCTAssertTrue(result)
    }

    func test_verifyOTP_all6Zeros_mock_returnsTrue() async {
        // Mock throws for "000000" but demo flow still returns true
        sut.otpCode = "000000"
        let result = await sut.verifyOTPCode()
        XCTAssertTrue(result)   // demo override returns true
    }

    // MARK: - Step 3: resetPassword

    func test_resetPassword_shortPassword_returnsFalse() async {
        sut.newPassword        = "abc"
        sut.confirmNewPassword = "abc"
        let result = await sut.resetPassword()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.newPasswordError)
    }

    func test_resetPassword_mismatchedPasswords_returnsFalse() async {
        sut.newPassword        = "Password@123"
        sut.confirmNewPassword = "Different@123"
        let result = await sut.resetPassword()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.confirmPasswordError)
    }

    func test_resetPassword_validPasswords_returnsTrue() async {
        sut.newPassword        = "NewPass@123"
        sut.confirmNewPassword = "NewPass@123"
        sut.otpCode            = "123456"
        let result = await sut.resetPassword()
        XCTAssertTrue(result)
    }

    func test_resetPassword_isLoading_falseAfterCompletion() async {
        sut.newPassword        = "NewPass@123"
        sut.confirmNewPassword = "NewPass@123"
        _ = await sut.resetPassword()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Password strength indicators

    func test_hasMinLength_trueWhen8Chars() {
        sut.newPassword = "12345678"
        XCTAssertTrue(sut.hasMinLength)
    }

    func test_hasMinLength_falseWhenShort() {
        sut.newPassword = "1234"
        XCTAssertFalse(sut.hasMinLength)
    }

    func test_hasSymbolOrNumber_trueWithSymbol() {
        sut.newPassword = "password!"
        XCTAssertTrue(sut.hasSymbolOrNumber)
    }

    func test_passwordsMatch_trueWhenSame() {
        sut.newPassword        = "Pass@123"
        sut.confirmNewPassword = "Pass@123"
        XCTAssertTrue(sut.passwordsMatch)
    }

    // MARK: - reset()

    func test_reset_clearsAllState() async {
        sut.email              = "test@example.com"
        sut.otpCode            = "123456"
        sut.newPassword        = "Pass@123"
        sut.confirmNewPassword = "Pass@123"
        sut.reset()
        XCTAssertTrue(sut.email.isEmpty)
        XCTAssertTrue(sut.otpCode.isEmpty)
        XCTAssertTrue(sut.newPassword.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }
}
