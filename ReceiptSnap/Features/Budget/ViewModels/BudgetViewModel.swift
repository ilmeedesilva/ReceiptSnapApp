import SwiftUI
import Combine
import CoreData

@MainActor
final class BudgetViewModel: ObservableObject {


    @Published var selectedMonth:          String = ""
    @Published var targetAmount:           String = ""
    @Published var overBudgetAlertEnabled: Bool   = true
    @Published var alertThreshold:         Double = 0.80   


    @Published var isLoading:    Bool    = false
    @Published var errorMessage: String? = nil


    @Published var budgetHistory: [BudgetHistoryItem] = []
    @Published var weeklyTrend:   [DailySpending]     = []
    @Published var budgets:       [Budget]            = []


    var onBudgetSaved:   ((Budget) -> Void)?
    var onBudgetDeleted: (() -> Void)?

    private let budgetService:       BudgetServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let persistence:         PersistenceController
    private let receiptService:      ReceiptServiceProtocol


    init(
        budgetService:       BudgetServiceProtocol       = ServiceLocator.shared.budgetService,
        notificationService: NotificationServiceProtocol = ServiceLocator.shared.notificationService,
        persistence:         PersistenceController       = ServiceLocator.shared.persistence,
        receiptService:      ReceiptServiceProtocol      = ServiceLocator.shared.receiptService
    ) {
        self.budgetService       = budgetService
        self.notificationService = notificationService
        self.persistence         = persistence
        self.receiptService      = receiptService

        let f = DateFormatter(); f.dateFormat = "MMMM"
        selectedMonth = f.string(from: Date())
    }


    enum ValidationError: LocalizedError {
        case invalidAmount
        var errorDescription: String? { "Please enter a valid amount greater than zero." }
    }


    func saveBudget(userId: String) async {
        guard let amount = parsedAmount(), amount > 0 else {
            errorMessage = "Please enter a valid amount."; return
        }
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please sign in before saving a budget."
            return
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        let period = periodString(for: selectedMonth)
        do {
            let budget = try await budgetService.createBudget(
                userId:         userId,
                monthlyLimit:   amount,
                period:         period,
                alertEnabled:   overBudgetAlertEnabled,
                alertThreshold: alertThreshold
            )
            await loadBudgetHistory(userId: userId)
            saveToCoreData(budget)
            onBudgetSaved?(budget)
        } catch let error as ServiceError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not save budget. Please try again."
        }
    }

    func updateBudget(_ existing: Budget, userId: String) async {
        guard let amount = parsedAmount(), amount > 0 else {
            errorMessage = "Please enter a valid amount."; return
        }
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        var updated = Budget(
            id:              existing.id,
            userId:          userId,
            monthlyLimit:    amount,
            currentSpending: existing.currentSpending,
            period:          existing.period,
            alertEnabled:    overBudgetAlertEnabled,
            alertThreshold:  alertThreshold,
            createdAt:       existing.createdAt
        )

        do {
            updated = try await budgetService.updateBudget(updated)
        } catch {
        
        }
        await loadBudgetHistory(userId: userId)
        saveToCoreData(updated)
        if updated.hasReachedAlertThreshold || updated.isOverBudget {
            try? await notificationService.scheduleBudgetAlert(budget: updated)
        }
        onBudgetSaved?(updated)
    }

    func deleteBudget(id: UUID, userId: String) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await budgetService.deleteBudget(id: id, userId: userId)
        } catch {  }

        budgets.removeAll { $0.id == id }
        budgetHistory.removeAll { $0.id == id }
        deleteFromCoreData(id: id)
        onBudgetDeleted?()
    }

   
    func refreshSpending(budget: Budget, receipts: [Receipt]) async {
        var updated = budget
        budgetService.recalculateSpending(for: &updated, receipts: receipts)
        do { _ = try await budgetService.updateBudget(updated) } catch {}
        saveToCoreData(updated)

        if updated.hasReachedAlertThreshold || updated.isOverBudget {
            try? await notificationService.scheduleBudgetAlert(budget: updated)
        }
        onBudgetSaved?(updated)
    }

    func loadOverviewData(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        await loadBudgetHistory(userId: userId)
        weeklyTrend = DailySpending.mockWeek()
    }

    func prefillForEdit(_ budget: Budget) {
        targetAmount  = String(Int(budget.monthlyLimit))
        alertThreshold = budget.alertThreshold
        overBudgetAlertEnabled = budget.alertEnabled
        if let first = budget.period.split(separator: " ").first {
            selectedMonth = String(first)
        }
    }

    func loadBudgetHistory(userId: String) async {
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            budgets = []
            budgetHistory = []
            return
        }
        do {
            let fetched = try await budgetService.fetchBudgets(userId: userId)
            budgets = try await withBudgetSpendingApplied(fetched, userId: userId)
            budgetHistory = budgets.map(historyItem(from:))
            errorMessage = nil
        } catch {
            budgets = []
            budgetHistory = []
            if errorMessage == nil {
                errorMessage = "Could not load budget activity."
            }
        }
    }

    func budget(for id: UUID) -> Budget? {
        budgets.first { $0.id == id }
    }

    func isEditable(_ budget: Budget) -> Bool {
        periodRelation(for: budget) != .past
    }

    func isUpcoming(_ budget: Budget) -> Bool {
        periodRelation(for: budget) == .future
    }

    func availableBudgetYears() -> [Int] {
        Array(Set(budgets.map(\.year))).sorted(by: >)
    }

    func parsedAmount() -> Double? {
        let cleaned = targetAmount
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    var availableMonths: [String] {
        let allMonths = ["January","February","March","April","May","June",
                         "July","August","September","October","November","December"]
        let currentMonthIndex = max(Calendar.current.component(.month, from: Date()) - 1, 0)
        return Array(allMonths.dropFirst(currentMonthIndex))
    }

    func periodString(for month: String) -> String {
        "\(month) \(Calendar.current.component(.year, from: Date()))"
    }

    private enum BudgetPeriodRelation {
        case past, current, future
    }

    private func periodRelation(for budget: Budget) -> BudgetPeriodRelation {
        let cal = Calendar.current
        let now = Date()
        let currentYear = cal.component(.year, from: now)
        let currentMonth = cal.component(.month, from: now)

        if budget.year < currentYear { return .past }
        if budget.year > currentYear { return .future }
        if budget.month < currentMonth { return .past }
        if budget.month > currentMonth { return .future }
        return .current
    }

    private func withBudgetSpendingApplied(_ items: [Budget], userId: String) async throws -> [Budget] {
        let allReceipts = (try? await receiptService.fetchReceipts(userId: userId)) ?? []
        var updated: [Budget] = []
        for budget in items.sorted(by: { lhs, rhs in
            if lhs.year == rhs.year { return lhs.month > rhs.month }
            return lhs.year > rhs.year
        }) {
            if isUpcoming(budget) {
                var futureBudget = budget
                futureBudget.currentSpending = 0
                updated.append(futureBudget)
                continue
            }

            var hydrated = budget
            hydrated.currentSpending = budgetService.totalSpending(
                userId: userId,
                month: budget.month,
                year: budget.year,
                receipts: allReceipts
            )
            updated.append(hydrated)
        }
        return updated
    }

    private func historyItem(from budget: Budget) -> BudgetHistoryItem {
        let cal = Calendar.current
        let monthDate = cal.date(from: DateComponents(year: budget.year, month: budget.month, day: 1)) ?? Date()
        let daysInMonth = cal.range(of: .day, in: .month, for: monthDate)?.count ?? 30
        return BudgetHistoryItem(
            id: budget.id,
            period: budget.period,
            daysCompleted: daysInMonth,
            totalBudget: budget.monthlyLimit,
            actualSpend: budget.currentSpending
        )
    }


    private func saveToCoreData(_ budget: Budget) {
        persistence.performBackgroundTask { ctx in
            let req = CDBudget.fetchRequest(userId: budget.userId ?? "",
                                             month: budget.month, year: budget.year)
            let entity = (try? ctx.fetch(req).first) ?? CDBudget(context: ctx)
            entity.populate(from: budget)
        }
    }

    private func deleteFromCoreData(id: UUID) {
        persistence.performBackgroundTask { ctx in
            let req = NSFetchRequest<CDBudget>(entityName: "CDBudget")
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            (try? ctx.fetch(req))?.forEach { ctx.delete($0) }
        }
    }
}