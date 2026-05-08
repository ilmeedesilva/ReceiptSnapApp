import XCTest
@testable import ReceiptSnap

@MainActor
final class ReportsViewModelTests: XCTestCase {

    func test_derivedWeeklyState_returnsActivePastAndTotalSpend() {
        let active = makeWeek(status: .active, totalSpent: 25)
        let finalized = makeWeek(status: .finalized, totalSpent: 75)
        let sut = ReportsViewModel(
            reportService: ReportService(),
            receiptService: MockReceiptService(),
            budgetService: MockBudgetService()
        )
        sut.weeklyReports = [active, finalized]

        XCTAssertEqual(sut.activeWeek?.status, .active)
        XCTAssertEqual(sut.pastWeeks.count, 1)
        XCTAssertEqual(sut.totalMonthlySpend, 100)
    }

    func test_monthlyBudgetUsed_clampsToOne() {
        let sut = ReportsViewModel(
            reportService: ReportService(),
            receiptService: MockReceiptService(),
            budgetService: MockBudgetService()
        )
        sut.monthlyReports = [
            makeMonth(month: "May", budgetUsedPercent: 125)
        ]

        XCTAssertEqual(sut.monthlyBudgetUsed, 1.0)
    }

    func test_monthItems_marksMonthsWithReportData() {
        let sut = ReportsViewModel(
            reportService: ReportService(),
            receiptService: MockReceiptService(),
            budgetService: MockBudgetService()
        )
        sut.monthlyReports = [
            makeMonth(month: "January", year: "2026", totalSpent: 42, receiptCount: 3)
        ]

        let items = sut.monthItems(for: 2026)
        let january = items.first { $0.month == "January" }
        let february = items.first { $0.month == "February" }

        XCTAssertEqual(january?.hasData, true)
        XCTAssertEqual(january?.totalSpent, 42)
        XCTAssertEqual(january?.receiptCount, 3)
        XCTAssertEqual(february?.hasData, false)
    }

    func test_loadReports_withoutUserId_usesMockReports() async {
        let sut = ReportsViewModel(
            reportService: ReportService(),
            receiptService: MockReceiptService(),
            budgetService: MockBudgetService()
        )

        await sut.loadReports(userId: nil)

        XCTAssertFalse(sut.weeklyReports.isEmpty)
        XCTAssertFalse(sut.monthlyReports.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }

    private func makeWeek(status: WeekStatus, totalSpent: Double) -> WeeklyReportData {
        WeeklyReportData(
            dateRange: "May 4 - May 10",
            year: "2026",
            status: status,
            receiptCount: 1,
            totalSpent: totalSpent,
            vsLastWeek: nil,
            vsLastWeekAmount: nil,
            dailySpending: [],
            topCategories: [],
            highValueItems: []
        )
    }

    private func makeMonth(
        month: String,
        year: String = "2026",
        totalSpent: Double = 0,
        receiptCount: Int = 0,
        budgetUsedPercent: Int = 0
    ) -> MonthlyReportData {
        MonthlyReportData(
            month: month,
            year: year,
            totalSpent: totalSpent,
            avgPerDay: 0,
            receiptCount: receiptCount,
            budgetUsedPercent: budgetUsedPercent,
            categories: [],
            insights: MonthlyInsights(
                mostExpensiveDay: "-",
                mostExpensiveDayAmount: 0,
                topCategory: "-",
                topCategoryPercent: 0
            )
        )
    }
}
