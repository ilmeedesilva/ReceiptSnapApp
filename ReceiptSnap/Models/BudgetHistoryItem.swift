import Foundation

struct BudgetHistoryItem: Identifiable, Equatable {

    let id: UUID
    let period: String         
    let daysCompleted: Int
    let totalBudget: Double
    let actualSpend: Double

    init(
        id: UUID = UUID(),
        period: String,
        daysCompleted: Int,
        totalBudget: Double,
        actualSpend: Double
    ) {
        self.id            = id
        self.period        = period
        self.daysCompleted = daysCompleted
        self.totalBudget   = totalBudget
        self.actualSpend   = actualSpend
    }


    var isOverBudget: Bool { actualSpend > totalBudget }

    var percentDiff: Double {
        guard totalBudget > 0 else { return 0 }
        return abs((totalBudget - actualSpend) / totalBudget * 100)
    }

    var statusLabel: String {
        let pct = Int(percentDiff.rounded())
        return isOverBudget ? "\(pct)% over budget" : "\(pct)% under budget"
    }


    var spendingProgress: Double {
        min(actualSpend / max(totalBudget, 1), 1.5)
    }


    static func mockHistory() -> [BudgetHistoryItem] {
        [
            BudgetHistoryItem(period: "March 2026",    daysCompleted: 31, totalBudget: 2_500, actualSpend: 2_134.79),
            BudgetHistoryItem(period: "February 2026", daysCompleted: 28, totalBudget: 2_200, actualSpend: 1_980.45),
            BudgetHistoryItem(period: "January 2026",  daysCompleted: 31, totalBudget: 2_000, actualSpend: 2_310.00),
            BudgetHistoryItem(period: "December 2025", daysCompleted: 31, totalBudget: 3_000, actualSpend: 2_875.50),
            BudgetHistoryItem(period: "November 2025", daysCompleted: 30, totalBudget: 2_000, actualSpend: 1_650.00),
            BudgetHistoryItem(period: "October 2025",  daysCompleted: 31, totalBudget: 1_800, actualSpend: 1_920.00),
            BudgetHistoryItem(period: "September 2025",daysCompleted: 30, totalBudget: 2_000, actualSpend: 1_742.30),
            BudgetHistoryItem(period: "August 2025",   daysCompleted: 31, totalBudget: 2_200, actualSpend: 2_185.00),
            BudgetHistoryItem(period: "July 2025",     daysCompleted: 31, totalBudget: 2_500, actualSpend: 2_640.80),
            BudgetHistoryItem(period: "June 2025",     daysCompleted: 30, totalBudget: 2_000, actualSpend: 1_880.50),
            BudgetHistoryItem(period: "May 2025",      daysCompleted: 31, totalBudget: 1_800, actualSpend: 1_755.90),
            BudgetHistoryItem(period: "April 2025",    daysCompleted: 30, totalBudget: 1_800, actualSpend: 1_930.00),
        ]
    }
}
