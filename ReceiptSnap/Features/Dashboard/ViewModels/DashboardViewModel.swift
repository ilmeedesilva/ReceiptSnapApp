import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {


    @Published var budget:             Budget?            = nil
    @Published var totalSpending:      Double             = 0
    @Published var spendingCategories: [SpendingCategory] = []
    @Published var recentReceipts:     [Receipt]          = []
    @Published var reports:            [ReportItem]       = []
    @Published var isLoading:          Bool               = false
    @Published var errorMessage:       String?            = nil


    private let budgetService:  BudgetServiceProtocol
    private let receiptService: ReceiptServiceProtocol


    init(
        budgetService:  BudgetServiceProtocol  = ServiceLocator.shared.budgetService,
        receiptService: ReceiptServiceProtocol = ServiceLocator.shared.receiptService
    ) {
        self.budgetService  = budgetService
        self.receiptService = receiptService
    }


    func loadDashboard(userId: String? = nil) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let cal   = Calendar.current
        let now   = Date()
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year,  from: now)

        guard let uid = userId, !uid.isEmpty else {
            await loadMockData(); return
        }

        do {
            async let allReceiptsTask = receiptService.fetchReceipts(userId: uid)
            async let budgetTask = budgetService.fetchBudget(userId: uid, month: month, year: year)

            let allReceipts = try await allReceiptsTask
            let thisMonthReceipts = allReceipts.filter {
                let components = cal.dateComponents([.month, .year], from: $0.date)
                return components.month == month && components.year == year
            }

            budget = try await budgetTask
            recentReceipts = Array(allReceipts.sorted { $0.date > $1.date }.prefix(5))
            totalSpending = thisMonthReceipts.reduce(0) { $0 + abs($1.amount) }
            spendingCategories = budgetService.categoryBreakdown(
                userId: uid,
                month: month,
                year: year,
                receipts: allReceipts
            )

            if var b = budget {
                b.currentSpending = totalSpending
                budget = b
            }
            reports = ReportItem.mockReports()
        } catch {
            budget = nil
            recentReceipts = []
            totalSpending = 0
            spendingCategories = []
            reports = ReportItem.mockReports()
            errorMessage = "Could not load dashboard data."
        }
    }


    func setBudget(monthlyLimit: Double, userId: String) {
        Task {
            do {
                let b = try await budgetService.createBudget(
                    userId:         userId,
                    monthlyLimit:   monthlyLimit,
                    period:         currentPeriodString(),
                    alertEnabled:   true,
                    alertThreshold: 0.80
                )
                budget = b
            } catch {
                // Local fallback
                budget = Budget(userId: userId, monthlyLimit: monthlyLimit,
                                currentSpending: totalSpending,
                                period: currentPeriodString())
            }
        }
    }

    func clearBudget(userId: String) {
        guard let b = budget else { return }
        Task {
            try? await budgetService.deleteBudget(id: b.id, userId: userId)
            budget = nil
        }
    }

    func toggleBudgetPreview() {
        budget = budget == nil ? Budget.mock() : nil
    }


    var budgetProgressColor: Color {
        guard let b = budget else { return .rsForestGreen }
        return b.isOverBudget ? .rsError : .rsForestGreen
    }

    var hasBudgetWarning: Bool { budget?.isOverBudget ?? false }


    private func loadMockData() async {
        let cal   = Calendar.current
        let now   = Date()
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year,  from: now)

        let allReceipts  = (try? await receiptService.fetchReceipts(userId: "demo")) ?? MockData.receipts
        let thisMonth = allReceipts.filter {
            let c = cal.dateComponents([.month, .year], from: $0.date)
            return c.month == month && c.year == year
        }
        let total = thisMonth.reduce(0) { $0 + abs($1.amount) }

        var grouped: [ReceiptCategory: Double] = [:]
        for r in thisMonth { grouped[r.category, default: 0] += abs(r.amount) }

        spendingCategories = ReceiptCategory.allCases.compactMap { cat in
            let amount = grouped[cat] ?? 0
            guard amount > 0 else { return nil }
            return SpendingCategory(category: cat,
                                    totalAmount: amount,
                                    percentage: total > 0 ? amount / total : 0)
        }.sorted { $0.totalAmount > $1.totalAmount }

        totalSpending  = total
        budget         = MockData.budget
        recentReceipts = Array(allReceipts.sorted { $0.date > $1.date }.prefix(5))
        reports        = ReportItem.mockReports()
    }

    private func currentPeriodString() -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }
}