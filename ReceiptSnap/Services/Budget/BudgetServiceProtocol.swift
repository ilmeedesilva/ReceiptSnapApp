
import Foundation


protocol BudgetServiceProtocol: AnyObject {

    /// Fetch the active budget for the given month/year. Returns nil when none set.
    func fetchBudget(userId: String, month: Int, year: Int) async throws -> Budget?

    /// Fetch all budget records for the user (history view).
    func fetchBudgets(userId: String) async throws -> [Budget]

    /// Create a new monthly budget. Replaces any existing budget for the same period.
    func createBudget(userId: String, monthlyLimit: Double, period: String,
                      alertEnabled: Bool, alertThreshold: Double) async throws -> Budget

    /// Persist changes to an existing budget (new limit, spending update, alert toggle).
    func updateBudget(_ budget: Budget) async throws -> Budget

    /// Delete the budget for the given ID.
    func deleteBudget(id: UUID, userId: String) async throws

    /// Recalculate and persist currentSpending for the budget month from receipts.
    func recalculateSpending(for budget: inout Budget, receipts: [Receipt])

    /// Total spending for the given month, computed from a receipt list.
    func totalSpending(userId: String, month: Int, year: Int,
                       receipts: [Receipt]) -> Double

    /// Spending grouped by category for the given month.
    func categoryBreakdown(userId: String, month: Int, year: Int,
                           receipts: [Receipt]) -> [SpendingCategory]
}


extension BudgetServiceProtocol {

    func recalculateSpending(for budget: inout Budget, receipts: [Receipt]) {
        let cal = Calendar.current
        let total = receipts
            .filter {
                let c = cal.dateComponents([.month, .year], from: $0.date)
                return c.month == budget.month && c.year == budget.year
            }
            .reduce(0) { $0 + abs($1.amount) }
        budget.currentSpending = total
    }

    func totalSpending(userId: String, month: Int, year: Int, receipts: [Receipt]) -> Double {
        let cal = Calendar.current
        return receipts
            .filter { ($0.userId == nil || $0.userId == userId) }
            .filter {
                let c = cal.dateComponents([.month, .year], from: $0.date)
                return c.month == month && c.year == year
            }
            .reduce(0) { $0 + abs($1.amount) }
    }

    func categoryBreakdown(userId: String, month: Int, year: Int,
                           receipts: [Receipt]) -> [SpendingCategory] {
        let cal = Calendar.current
        let filtered = receipts
            .filter { ($0.userId == nil || $0.userId == userId) }
            .filter {
                let c = cal.dateComponents([.month, .year], from: $0.date)
                return c.month == month && c.year == year
            }

        let total = filtered.reduce(0) { $0 + abs($1.amount) }
        var grouped: [ReceiptCategory: Double] = [:]
        for r in filtered { grouped[r.category, default: 0] += abs(r.amount) }

        return ReceiptCategory.allCases.compactMap { cat in
            let amount = grouped[cat] ?? 0
            guard amount > 0 else { return nil }
            return SpendingCategory(
                category: cat,
                totalAmount: amount,
                percentage: total > 0 ? amount / total : 0
            )
        }.sorted { $0.totalAmount > $1.totalAmount }
    }
}
