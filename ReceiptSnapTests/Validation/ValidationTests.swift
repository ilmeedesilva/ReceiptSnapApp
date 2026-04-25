
import XCTest
@testable import ReceiptSnap

final class ValidationTests: XCTestCase {

    // MARK: - Email
    func test_validEmails() {
        let valid = [
            "user@example.com",
            "firstname.lastname@domain.co.uk",
            "user+tag@subdomain.example.org",
            "test123@test.io"
        ]
        valid.forEach { XCTAssertTrue($0.isValidEmail, "\($0) should be valid") }
    }

    func test_invalidEmails() {
        let invalid = [
            "",
            "notanemail",
            "@missinglocal.com",
            "missing@domain",
            "spaces in@email.com",
            "double@@at.com"
        ]
        invalid.forEach { XCTAssertFalse($0.isValidEmail, "\($0) should be invalid") }
    }

    // MARK: - Password length
    func test_validPassword_atLeast8Chars() {
        XCTAssertTrue("12345678".isValidPassword)
        XCTAssertTrue("abcdefgh".isValidPassword)
    }

    func test_invalidPassword_lessThan8Chars() {
        XCTAssertFalse("1234567".isValidPassword)
        XCTAssertFalse("".isValidPassword)
    }

    // MARK: - hasMinLength
    func test_hasMinLength_exactlyEight() {
        XCTAssertTrue("aaaaaaaa".hasMinLength)
    }

    func test_hasMinLength_sevenChars_returnsFalse() {
        XCTAssertFalse("aaaaaaa".hasMinLength)
    }

    // MARK: - containsSymbolOrNumber
    func test_containsSymbolOrNumber_withDigit() {
        XCTAssertTrue("password1".containsSymbolOrNumber)
    }

    func test_containsSymbolOrNumber_withSymbol() {
        XCTAssertTrue("password!".containsSymbolOrNumber)
        XCTAssertTrue("pass@word".containsSymbolOrNumber)
    }

    func test_containsSymbolOrNumber_lettersOnly_returnsFalse() {
        XCTAssertFalse("passwordonly".containsSymbolOrNumber)
    }

    // MARK: - isValidName
    func test_validName_atLeast2Chars() {
        XCTAssertTrue("Jo".isValidName)
        XCTAssertTrue("Alice Smith".isValidName)
    }

    func test_invalidName_singleChar() {
        XCTAssertFalse("A".isValidName)
        XCTAssertFalse("".isValidName)
        XCTAssertFalse("  ".isValidName)  // whitespace only
    }

    // MARK: - isValidOTP
    func test_validOTP_exactly6Digits() {
        XCTAssertTrue("123456".isValidOTP)
        XCTAssertTrue("000000".isValidOTP)
    }

    func test_invalidOTP_lessThan6() {
        XCTAssertFalse("12345".isValidOTP)
    }

    func test_invalidOTP_moreThan6() {
        XCTAssertFalse("1234567".isValidOTP)
    }

    func test_invalidOTP_letters() {
        XCTAssertFalse("abcdef".isValidOTP)
        XCTAssertFalse("12345a".isValidOTP)
    }

    // MARK: - isValidPasscode
    func test_validPasscode_6Digits() {
        XCTAssertTrue("654321".isValidPasscode)
    }

    func test_invalidPasscode_alphanumeric() {
        XCTAssertFalse("12345a".isValidPasscode)
    }

    // MARK: - containsUppercase
    func test_containsUppercase_true() {
        XCTAssertTrue("Password".containsUppercase)
    }

    func test_containsUppercase_false() {
        XCTAssertFalse("password".containsUppercase)
    }
}
