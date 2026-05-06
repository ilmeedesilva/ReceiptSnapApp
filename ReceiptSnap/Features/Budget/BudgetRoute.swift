import Foundation

enum BudgetRoute: Hashable {
    case setBudget
    case budgetOverview
    case editBudget(id: UUID)
    case budgetHistory
    case budgetDetail(id: UUID)
    case budgetFeedback
    case budgetExceeded
    case budgetSetSuccess
    case budgetDeleteSuccess
    case expenseSummary
    case reports
    case weeklyReport(dateRange: String)
    case monthlyReport(month: String)
}