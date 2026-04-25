
import Foundation

final class MockBudgetService: BudgetServiceProtocol {

    var mockBudgets: [Budget]  = {
        let cal = Calendar.current
        func daysAgo(_ months: Int) -> Date {
            cal.date(byAdding: .month, value: -months, to: Date()) ?? Date()
        }
        return [
            Budget.mock(),   // current month — April 2026
            Budget(monthlyLimit: 2_500, currentSpending: 2_134.79, period: "March 2026",    createdAt: daysAgo(1)),
            Budget(monthlyLimit: 2_200, currentSpending: 1_980.45, period: "February 2026", createdAt: daysAgo(2)),
            Budget(monthlyLimit: 2_000, currentSpending: 2_310.00, period: "January 2026",  createdAt: daysAgo(3)),
            Budget(monthlyLimit: 3_000, currentSpending: 2_875.50, period: "December 2025", createdAt: daysAgo(4)),
            Budget(monthlyLimit: 2_000, currentSpending: 1_650.00, period: "November 2025", createdAt: daysAgo(5)),
            Budget(monthlyLimit: 1_800, currentSpending: 1_920.00, period: "October 2025",  createdAt: daysAgo(6)),
        ]
    }()
    var shouldThrow: Bool      = false

    private func maybeThrow() throws {
        if shouldThrow { throw ServiceError.networkError("Mock error") }
    }

    func fetchBudget(userId: String, month: Int, year: Int) async throws -> Budget? {
        try maybeThrow()
        return mockBudgets.first { $0.month == month && $0.year == year }
    }

    func fetchBudgets(userId: String) async throws -> [Budget] {
        try maybeThrow()
        return mockBudgets.sorted { $0.createdAt > $1.createdAt }
    }

    func createBudget(userId: String, monthlyLimit: Double, period: String,
                      alertEnabled: Bool, alertThreshold: Double) async throws -> Budget {
        try maybeThrow()
        let b = Budget(userId: userId, monthlyLimit: monthlyLimit, currentSpending: 0,
                       period: period, alertEnabled: alertEnabled, alertThreshold: alertThreshold)
        // Remove existing budget for same period
        mockBudgets.removeAll { $0.period == period }
        mockBudgets.append(b)
        return b
    }

    func updateBudget(_ budget: Budget) async throws -> Budget {
        try maybeThrow()
        if let i = mockBudgets.firstIndex(where: { $0.id == budget.id }) {
            mockBudgets[i] = budget
        }
        return budget
    }

    func deleteBudget(id: UUID, userId: String) async throws {
        try maybeThrow()
        mockBudgets.removeAll { $0.id == id }
    }
}
