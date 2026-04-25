import XCTest
@testable import ReceiptSnap

final class KeychainServiceTests: XCTestCase {

    var sut: KeychainService!

    override func setUp() {
        super.setUp()
        sut = KeychainService.shared
        sut.clearAll() 
    }

    override func tearDown() {
        sut.clearAll()
        super.tearDown()
    }


    func test_save_load_roundtrip() {
        let saved = sut.save("hello", for: .passcode)
        XCTAssertTrue(saved)
        XCTAssertEqual(sut.load(for: .passcode), "hello")
    }

    func test_load_missingKey_returnsNil() {
        XCTAssertNil(sut.load(for: .passcode))
    }

    func test_save_overwritesExistingValue() {
        sut.save("first",  for: .passcode)
        sut.save("second", for: .passcode)
        XCTAssertEqual(sut.load(for: .passcode), "second")
    }


    func test_delete_removesValue() {
        sut.save("value", for: .lastLoggedEmail)
        sut.delete(for: .lastLoggedEmail)
        XCTAssertNil(sut.load(for: .lastLoggedEmail))
    }

    func test_delete_nonExistentKey_doesNotCrash() {
        XCTAssertFalse(sut.delete(for: .autoLoginToken))
    }

    func test_clearAll_removesAllKeys() {
        sut.save("a", for: .passcode)
        sut.save("b", for: .lastLoggedEmail)
        sut.clearAll()
        XCTAssertNil(sut.load(for: .passcode))
        XCTAssertNil(sut.load(for: .lastLoggedEmail))
    }


    func test_savePasscode_and_verifyPasscode_success() {
        sut.savePasscode("112233")
        XCTAssertTrue(sut.verifyPasscode("112233"))
    }

    func test_verifyPasscode_wrongCode_returnsFalse() {
        sut.savePasscode("112233")
        XCTAssertFalse(sut.verifyPasscode("000000"))
    }

    func test_hasPasscode_true_afterSave() {
        sut.savePasscode("999999")
        XCTAssertTrue(sut.hasPasscode())
    }

    func test_hasPasscode_false_whenNotSet() {
        XCTAssertFalse(sut.hasPasscode())
    }
}
