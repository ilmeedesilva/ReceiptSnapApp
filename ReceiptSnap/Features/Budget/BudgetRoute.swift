
import Foundation

enum BudgetRoute: Hashable {
    case setBudget
    case budgetOverview
    case editBudget
    case budgetHistory
    case budgetFeedback
    case budgetExceeded
    case budgetSetSuccess
    case budgetDeleteSuccess
    case expenseSummary
    case reports
    case weeklyReport(dateRange: String)
    case monthlyReport(month: String)
}
