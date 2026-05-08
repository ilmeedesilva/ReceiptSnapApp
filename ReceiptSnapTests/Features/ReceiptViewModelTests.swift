import XCTest
@testable import ReceiptSnap

@MainActor
final class ReceiptViewModelTests: XCTestCase {

    private var receiptService: MockReceiptService!
    private var sut: ReceiptViewModel!

    override func setUp() {
        super.setUp()
        receiptService = MockReceiptService()
        receiptService.mockReceipts = []
        sut = ReceiptViewModel(
            receiptService: receiptService,
            searchService: SearchService(),
            splitService: SplitService(),
            persistence: PersistenceController(inMemory: true)
        )
    }

    override func tearDown() {
        sut = nil
        receiptService = nil
        super.tearDown()
    }

    func test_validate_emptyTitle_throwsMissingTitle() {
        let receipt = makeReceipt(title: "   ", amount: 10)

        XCTAssertThrowsError(try sut.validate(receipt)) { error in
            XCTAssertEqual(error.localizedDescription, "Please enter a merchant name.")
        }
    }

    func test_validate_zeroAmount_throwsZeroAmount() {
        let receipt = makeReceipt(amount: 0)

        XCTAssertThrowsError(try sut.validate(receipt)) { error in
            XCTAssertEqual(error.localizedDescription, "Amount must be greater than zero.")
        }
    }

    func test_addReceipt_validReceipt_insertsLocallyAndSavesToService() async {
        let receipt = makeReceipt(title: "Coffee", amount: -5.25)

        await sut.addReceipt(receipt)

        XCTAssertEqual(sut.receipts.first?.id, receipt.id)
        XCTAssertEqual(receiptService.mockReceipts.first?.id, receipt.id)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_addReceipt_serviceFailure_rollsBackLocalInsertAndSetsError() async {
        receiptService.shouldThrow = true
        let receipt = makeReceipt(title: "Coffee", amount: -5.25)

        await sut.addReceipt(receipt)

        XCTAssertFalse(sut.receipts.contains { $0.id == receipt.id })
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_filteredReceipts_appliesSearchAndCategory() {
        let coffee = makeReceipt(title: "Corner Coffee", category: .food, tags: ["work"])
        let fuel = makeReceipt(title: "Fuel Stop", category: .transport)
        sut.receipts = [coffee, fuel]

        sut.searchText = "coffee"
        sut.selectedCategory = .food

        XCTAssertEqual(sut.filteredReceipts, [coffee])
    }

    func test_totalSpending_usesAbsoluteAmountsForMonth() {
        let dateInMonth = makeDate(year: 2026, month: 5, day: 3)
        let otherMonth = makeDate(year: 2026, month: 4, day: 3)
        sut.receipts = [
            makeReceipt(date: dateInMonth, amount: -12),
            makeReceipt(date: dateInMonth, amount: 8),
            makeReceipt(date: otherMonth, amount: -100)
        ]

        XCTAssertEqual(sut.totalSpending(month: 5, year: 2026), 20)
    }

    func test_toggleFavorite_flipsReceiptFavoriteState() {
        let receipt = makeReceipt(isFavorite: false)
        sut.receipts = [receipt]

        sut.toggleFavorite(id: receipt.id)

        XCTAssertTrue(sut.receipt(for: receipt.id)?.isFavorite == true)
    }

    private func makeReceipt(
        title: String = "Merchant",
        category: ReceiptCategory = .food,
        date: Date = Date(),
        amount: Double = -10,
        isFavorite: Bool = false,
        tags: [String] = []
    ) -> Receipt {
        Receipt(
            userId: "user-1",
            title: title,
            category: category,
            date: date,
            amount: amount,
            isFavorite: isFavorite,
            tags: tags
        )
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
