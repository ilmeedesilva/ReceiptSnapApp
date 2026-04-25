
import SwiftUI
import Combine
import CoreData

@MainActor
final class BudgetViewModel: ObservableObject {

    // MARK: - Form state

    @Published var selectedMonth:          String = ""
    @Published var targetAmount:           String = ""
    @Published var overBudgetAlertEnabled: Bool   = true
    @Published var alertThreshold:         Double = 0.80   // 80 %

    // MARK: - Async state

    @Published var isLoading:    Bool    = false
    @Published var errorMessage: String? = nil

    // MARK: - Overview data

    @Published var budgetHistory: [BudgetHistoryItem] = []
    @Published var weeklyTrend:   [DailySpending]     = []

    // MARK: - Callbacks

    var onBudgetSaved:   ((Budget) -> Void)?
    var onBudgetDeleted: (() -> Void)?

    // MARK: - Dependencies

    private let budgetService:       BudgetServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let persistence:         PersistenceController

    // MARK: - Init

    init(
        budgetService:       BudgetServiceProtocol       = ServiceLocator.shared.budgetService,
        notificationService: NotificationServiceProtocol = ServiceLocator.shared.notificationService,
        persistence:         PersistenceController       = ServiceLocator.shared.persistence
    ) {
        self.budgetService       = budgetService
        self.notificationService = notificationService
        self.persistence         = persistence

        let f = DateFormatter(); f.dateFormat = "MMMM"
        selectedMonth = f.string(from: Date())
    }

    // MARK: - Validation

    enum ValidationError: LocalizedError {
        case invalidAmount
        var errorDescription: String? { "Please enter a valid amount greater than zero." }
    }

    // MARK: - Public API

    func saveBudget(userId: String) async {
        guard let amount = parsedAmount(), amount > 0 else {
            errorMessage = "Please enter a valid amount."; return
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
            saveToCoreData(budget)
            onBudgetSaved?(budget)
        } catch {
            // Fallback — local only
            let budget = Budget(
                userId:         userId,
                monthlyLimit:   amount,
                currentSpending: 0,
                period:         period,
                alertEnabled:   overBudgetAlertEnabled,
                alertThreshold: alertThreshold
            )
            saveToCoreData(budget)
            onBudgetSaved?(budget)
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
            alertThreshold:  alertThreshold
        )

        do {
            updated = try await budgetService.updateBudget(updated)
        } catch {
            // Proceed with local-only update
        }
        saveToCoreData(updated)

        // Schedule alert notification if threshold is newly reached
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
        } catch { /* local delete still proceeds */ }

        deleteFromCoreData(id: id)
        onBudgetDeleted?()
    }

    /// Called after new receipts are added — recalculates spending & fires alerts.
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

        do {
            let all = try await budgetService.fetchBudgets(userId: userId)
            let cal = Calendar.current
            budgetHistory = all
                .sorted { $0.createdAt > $1.createdAt }
                .map { b in
                    let daysInMonth = cal.range(of: .day, in: .month,
                        for: cal.date(from: DateComponents(year: b.year, month: b.month)) ?? Date()
                    )?.count ?? 30
                    return BudgetHistoryItem(
                        period:        b.period,
                        daysCompleted: daysInMonth,
                        totalBudget:   b.monthlyLimit,
                        actualSpend:   b.currentSpending
                    )
                }
        } catch {
            budgetHistory = BudgetHistoryItem.mockHistory()
        }
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

    // MARK: - Pure helpers (unit-testable)

    func parsedAmount() -> Double? {
        let cleaned = targetAmount
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }

    var availableMonths: [String] {
        ["January","February","March","April","May","June",
         "July","August","September","October","November","December"]
    }

    func periodString(for month: String) -> String {
        "\(month) \(Calendar.current.component(.year, from: Date()))"
    }

    // MARK: - CoreData

    private func saveToCoreData(_ budget: Budget) {
        persistence.performBackgroundTask { ctx in
            // Upsert
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
