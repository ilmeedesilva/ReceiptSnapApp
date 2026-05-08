import XCTest
@testable import ReceiptSnap

@MainActor
final class BudgetViewModelTests: XCTestCase {

    private var budgetService: MockBudgetService!
    private var receiptService: MockReceiptService!
    private var notificationService: RecordingNotificationService!
    private var sut: BudgetViewModel!

    override func setUp() {
        super.setUp()
        budgetService = MockBudgetService()
        budgetService.mockBudgets = []
        receiptService = MockReceiptService()
        receiptService.mockReceipts = []
        notificationService = RecordingNotificationService()
        sut = BudgetViewModel(
            budgetService: budgetService,
            notificationService: notificationService,
            persistence: PersistenceController(inMemory: true),
            receiptService: receiptService
        )
    }

    override func tearDown() {
        sut = nil
        notificationService = nil
        receiptService = nil
        budgetService = nil
        super.tearDown()
    }

    func test_parsedAmount_acceptsCurrencyAndCommas() {
        sut.targetAmount = "$1,250.50"

        XCTAssertEqual(sut.parsedAmount(), 1_250.50)
    }

    func test_saveBudget_invalidAmount_setsErrorAndDoesNotCreateBudget() async {
        sut.targetAmount = "0"

        await sut.saveBudget(userId: "user-1")

        XCTAssertEqual(sut.errorMessage, "Please enter a valid amount.")
        XCTAssertTrue(budgetService.mockBudgets.isEmpty)
    }

    func test_saveBudget_validInput_createsBudgetAndCallsCallback() async {
        var savedBudget: Budget?
        sut.targetAmount = "1500"
        sut.selectedMonth = "May"
        sut.onBudgetSaved = { savedBudget = $0 }

        await sut.saveBudget(userId: "user-1")

        XCTAssertEqual(budgetService.mockBudgets.count, 1)
        XCTAssertEqual(savedBudget?.monthlyLimit, 1_500)
        XCTAssertEqual(savedBudget?.userId, "user-1")
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func test_loadBudgetHistory_appliesReceiptSpendingAndSortsNewestFirst() async {
        let currentYear = Calendar.current.component(.year, from: Date())
        budgetService.mockBudgets = [
            Budget(userId: "user-1", monthlyLimit: 500, currentSpending: 0, period: "April \(currentYear)"),
            Budget(userId: "user-1", monthlyLimit: 700, currentSpending: 0, period: "May \(currentYear)")
        ]
        receiptService.mockReceipts = [
            Receipt(userId: "user-1", title: "Lunch", category: .food, date: makeDate(year: currentYear, month: 5, day: 4), amount: -12),
            Receipt(userId: "user-1", title: "Train", category: .transport, date: makeDate(year: currentYear, month: 5, day: 5), amount: -8)
        ]

        await sut.loadBudgetHistory(userId: "user-1")

        XCTAssertEqual(sut.budgets.map(\.period), ["May \(currentYear)", "April \(currentYear)"])
        XCTAssertEqual(sut.budgets.first?.currentSpending, 20)
        XCTAssertEqual(sut.budgetHistory.count, 2)
    }

    func test_budgetPeriodHelpers_classifyPastCurrentAndFuture() {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonthName = DateFormatter.monthName.string(from: Date())

        let past = Budget(monthlyLimit: 100, currentSpending: 10, period: "January \(currentYear - 1)")
        let current = Budget(monthlyLimit: 100, currentSpending: 10, period: "\(currentMonthName) \(currentYear)")
        let future = Budget(monthlyLimit: 100, currentSpending: 10, period: "December \(currentYear + 1)")

        XCTAssertFalse(sut.isEditable(past))
        XCTAssertTrue(sut.isEditable(current))
        XCTAssertTrue(sut.isUpcoming(future))
    }

    func test_refreshSpending_schedulesAlertWhenThresholdReached() async {
        let budget = Budget(
            userId: "user-1",
            monthlyLimit: 100,
            currentSpending: 0,
            period: "May 2026",
            alertEnabled: true,
            alertThreshold: 0.8
        )
        let receipts = [
            Receipt(userId: "user-1", title: "Groceries", category: .food, date: makeDate(year: 2026, month: 5, day: 1), amount: -85)
        ]

        await sut.refreshSpending(budget: budget, receipts: receipts)

        XCTAssertEqual(notificationService.scheduledBudgetAlerts.count, 1)
        XCTAssertEqual(notificationService.scheduledBudgetAlerts.first?.currentSpending, 85)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day))!
    }
}

private final class RecordingNotificationService: NotificationServiceProtocol {
    var scheduledBudgetAlerts: [Budget] = []

    func requestPermission() async -> Bool { true }
    func scheduleDailyReminder(at time: Date, message: String) async throws {}
    func cancelDailyReminder() async {}
    func scheduleBudgetAlert(budget: Budget) async throws {
        scheduledBudgetAlerts.append(budget)
    }
    func cancelAll() async {}
    func store(notification: AppNotification) {}
    func markRead(id: UUID) {}
}

private extension DateFormatter {
    static let monthName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
}
