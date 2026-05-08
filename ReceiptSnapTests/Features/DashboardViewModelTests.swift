import XCTest
@testable import ReceiptSnap

@MainActor
final class DashboardViewModelTests: XCTestCase {

    func test_loadDashboard_withoutUserId_loadsBaselineData() async {
        let sut = DashboardViewModel(
            budgetService: MockBudgetService(),
            receiptService: MockReceiptService()
        )

        await sut.loadDashboard(userId: "  ")

        XCTAssertGreaterThanOrEqual(sut.totalSpending, 0)
        XCTAssertNotNil(sut.budget)
        XCTAssertFalse(sut.recentReceipts.isEmpty)
        XCTAssertFalse(sut.reports.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadDashboard_withUserId_appliesCurrentMonthSpendingToBudget() async {
        let budgetService = MockBudgetService()
        let receiptService = MockReceiptService()
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let year = Calendar.current.component(.year, from: now)
        budgetService.mockBudgets = [
            Budget(userId: "user-1", monthlyLimit: 2_000, currentSpending: 0, period: "\(DateFormatter.monthName.string(from: now)) \(year)")
        ]
        receiptService.mockReceipts = [
            Receipt(userId: "user-1", title: "Big Shop", category: .shopping, date: now, amount: -1_000_000),
            Receipt(userId: "user-1", title: "Old", category: .food, date: makeDate(year: year, month: max(month - 1, 1), day: 1), amount: -50)
        ]
        let sut = DashboardViewModel(budgetService: budgetService, receiptService: receiptService)

        await sut.loadDashboard(userId: "user-1")

        XCTAssertGreaterThanOrEqual(sut.totalSpending, 1_000_000)
        XCTAssertEqual(sut.budget?.currentSpending, sut.totalSpending)
        XCTAssertEqual(sut.spendingCategories.first?.category, .shopping)
        XCTAssertLessThanOrEqual(sut.recentReceipts.count, 5)
        XCTAssertFalse(sut.isLoading)
    }

    func test_toggleBudgetPreview_switchesBetweenMockBudgetAndNil() {
        let sut = DashboardViewModel(
            budgetService: MockBudgetService(),
            receiptService: MockReceiptService()
        )

        sut.budget = nil
        sut.toggleBudgetPreview()
        XCTAssertNotNil(sut.budget)

        sut.toggleBudgetPreview()
        XCTAssertNil(sut.budget)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

private extension DateFormatter {
    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
}
