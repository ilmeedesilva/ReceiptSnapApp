import XCTest
@testable import ReceiptSnap

final class MainFeatureServiceTests: XCTestCase {

    func test_searchService_filtersByQueryCategoryFavoriteMinimumAndTags() {
        let service = SearchService()
        let match = makeReceipt(
            title: "Corner Coffee",
            category: .food,
            amount: -12,
            isFavorite: true,
            tags: ["work"]
        )
        let wrongCategory = makeReceipt(title: "Corner Coffee", category: .transport, amount: -12, isFavorite: true, tags: ["work"])
        let tooSmall = makeReceipt(title: "Corner Coffee", category: .food, amount: -4, isFavorite: true, tags: ["work"])
        let filter = ReceiptFilter(
            searchText: "coffee",
            categories: [.food],
            favoritesOnly: true,
            minimumAmount: 10,
            tags: ["work"]
        )

        let results = service.filter([match, wrongCategory, tooSmall], by: filter)

        XCTAssertEqual(results, [match])
    }

    func test_splitService_validatesEqualAndCustomSplits() {
        let service = SplitService()

        XCTAssertEqual(service.equalShare(total: -30, participants: 3), 10)
        XCTAssertTrue(service.validateCustomSplit(yourAmount: 12.50, otherAmount: 17.50, total: -30).isValid)
        XCTAssertFalse(service.validateCustomSplit(yourAmount: 5, otherAmount: 10, total: -30).isValid)
    }

    func test_reportService_weeklyReport_calculatesTotalsAndHighValueItems() {
        let service = ReportService()
        let weekStart = makeDate(year: 2026, month: 5, day: 4)
        let receipts = [
            makeReceipt(title: "Lunch", category: .food, date: makeDate(year: 2026, month: 5, day: 4), amount: -12),
            makeReceipt(title: "Shoes", category: .shopping, date: makeDate(year: 2026, month: 5, day: 5), amount: -80),
            makeReceipt(title: "Previous", category: .other, date: makeDate(year: 2026, month: 4, day: 29), amount: -50)
        ]

        let report = service.weeklyReport(receipts: receipts, weekStart: weekStart)

        XCTAssertEqual(report.receiptCount, 2)
        XCTAssertEqual(report.totalSpent, 92)
        XCTAssertEqual(report.highValueItems.first?.name, "Shoes")
        XCTAssertEqual(report.vsLastWeekAmount, 42)
    }

    func test_reportService_monthlyReport_usesBudgetAndCategoryBreakdown() {
        let service = ReportService()
        let receipts = [
            makeReceipt(title: "Lunch", category: .food, date: makeDate(year: 2026, month: 5, day: 4), amount: -20),
            makeReceipt(title: "Dinner", category: .food, date: makeDate(year: 2026, month: 5, day: 5), amount: -30),
            makeReceipt(title: "Taxi", category: .transport, date: makeDate(year: 2026, month: 5, day: 6), amount: -10)
        ]
        let budget = Budget(monthlyLimit: 100, currentSpending: 60, period: "May 2026")

        let report = service.monthlyReport(receipts: receipts, month: 5, year: 2026, budget: budget)

        XCTAssertEqual(report.month, "May")
        XCTAssertEqual(report.totalSpent, 60)
        XCTAssertEqual(report.receiptCount, 3)
        XCTAssertEqual(report.budgetUsedPercent, 60)
        XCTAssertEqual(report.categories.first?.name, ReceiptCategory.food.rawValue)
        XCTAssertEqual(report.insights.topCategory, ReceiptCategory.food.rawValue)
    }

    private func makeReceipt(
        title: String,
        category: ReceiptCategory,
        date: Date = Date(),
        amount: Double,
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
