import XCTest
@testable import ReceiptSnap

@MainActor
final class BiometricViewModelTests: XCTestCase {

    var sut: BiometricViewModel!
    var mockBiometric: MockBiometricService!
    var mockKeychain:  KeychainService!

    override func setUp() {
        super.setUp()
        mockBiometric = MockBiometricService()
        mockKeychain  = KeychainService.shared
        mockKeychain.delete(for: .passcode) 
        sut = BiometricViewModel(biometricService: mockBiometric, keychain: mockKeychain)
    }

    override func tearDown() {
        mockKeychain.delete(for: .passcode)
        sut = nil
        super.tearDown()
    }

    func test_biometricType_returnsFaceIDFromMock() {
        mockBiometric.biometricType = .faceID
        XCTAssertEqual(sut.biometricType, .faceID)
    }

    func test_isBiometricAvailable_trueFromMock() {
        mockBiometric.isBiometricAvailable = true
        XCTAssertTrue(sut.isBiometricAvailable)
    }


    func test_authenticateWithBiometrics_success_returnsTrue() async {
        mockBiometric.shouldSucceed = true
        let result = await sut.authenticateWithBiometrics()
        XCTAssertTrue(result)
        XCTAssertTrue(sut.authSuccess)
    }

    func test_authenticateWithBiometrics_failure_returnsFalse() async {
        mockBiometric.shouldSucceed = false
        let result = await sut.authenticateWithBiometrics()
        XCTAssertFalse(result)
    }

    func test_authenticateWithBiometrics_throws_setsErrorMessage() async {
        mockBiometric.shouldThrow = .notAvailable
        _ = await sut.authenticateWithBiometrics()
        XCTAssertNotNil(sut.errorMessage)
    }

    func test_authenticateWithBiometrics_isLoading_falseAfterCompletion() async {
        _ = await sut.authenticateWithBiometrics()
        XCTAssertFalse(sut.isAuthenticating)
    }


    func test_appendDigit_increments_createStep() {
        sut.appendDigit("1")
        XCTAssertEqual(sut.passcodeDigits, "1")
    }

    func test_appendDigit_maxes_at6() {
        "1234567".forEach { sut.appendDigit(String($0)) }
        XCTAssertEqual(sut.passcodeDigits.count, 6)
    }

    func test_deleteDigit_removes_lastChar() {
        sut.appendDigit("1")
        sut.appendDigit("2")
        sut.deleteDigit()
        XCTAssertEqual(sut.passcodeDigits, "1")
    }

    func test_advancePasscode_incompleteCode_returnsFalse() {
        sut.passcodeDigits = "123"
        let result = sut.advancePasscode()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.passcodeError)
    }

    func test_advancePasscode_completeCode_movesToConfirm() {
        sut.passcodeDigits = "123456"
        let result = sut.advancePasscode()
        XCTAssertFalse(result)   
        XCTAssertEqual(sut.passcodeStep, .confirm)
    }

    func test_advancePasscode_matchingConfirm_savesPasscode() {
        sut.passcodeDigits  = "123456"
        _ = sut.advancePasscode()   
        sut.passcodeConfirm = "123456"
        let result = sut.advancePasscode()
        XCTAssertTrue(result)
        XCTAssertTrue(mockKeychain.verifyPasscode("123456"))
    }

    func test_advancePasscode_mismatchingConfirm_setsError() {
        sut.passcodeDigits  = "123456"
        _ = sut.advancePasscode()
        sut.passcodeConfirm = "654321"
        let result = sut.advancePasscode()
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.passcodeError)
    }

    func test_resetPasscode_clearsAllState() {
        sut.passcodeDigits = "123456"
        sut.passcodeStep   = .confirm
        sut.resetPasscode()
        XCTAssertEqual(sut.passcodeDigits, "")
        XCTAssertEqual(sut.passcodeStep, .create)
    }
}
