import SwiftUI
import Combine

enum SummaryMode: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case shared  = "Shared"
    var id: String { rawValue }
}

struct WeeklySpend: Identifiable, Equatable {
    let id    = UUID()
    let label:  String
    let amount: Double
}

struct CategoryExpense: Identifiable, Equatable {
    let id       = UUID()
    let category: ReceiptCategory
    let amount:   Double
    let total:    Double

    var fraction: Double { total > 0 ? min(amount / total, 1.0) : 0 }

    var displayLabel: String {
        switch category {
        case .food:      return "Food & Dining"
        case .transport: return "Transport"
        case .shopping:  return "Shopping"
        case .bills:     return "Bills & Utilities"
        case .other:     return "Other"
        }
    }
}

@MainActor
final class ExpenseSummaryViewModel: ObservableObject {

    @Published var summaryMode: SummaryMode = .monthly
    @Published var isLoading:   Bool        = false

    @Published var monthlyTotal:      Double            = 0
    @Published var monthlyWeekly:     [WeeklySpend]     = []
    @Published var monthlyCategories: [CategoryExpense] = []

    @Published var sharedTotal:      Double            = 0
    @Published var othersPaid:       Double            = 0
    @Published var sharedWeekly:     [WeeklySpend]     = []
    @Published var sharedCategories: [CategoryExpense] = []

    var currentWeekly:     [WeeklySpend]      { summaryMode == .monthly ? monthlyWeekly    : sharedWeekly    }
    var currentCategories: [CategoryExpense]  { summaryMode == .monthly ? monthlyCategories : sharedCategories }
    var topCategory: CategoryExpense?         { currentCategories.max { $0.amount < $1.amount } }


    private let receiptService: ReceiptServiceProtocol
    private let splitService:   SplitService

    init(
        receiptService: ReceiptServiceProtocol = ServiceLocator.shared.receiptService,
        splitService:   SplitService           = ServiceLocator.shared.splitService
    ) {
        self.receiptService = receiptService
        self.splitService   = splitService
    }

    func loadSummary(userId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        let cal   = Calendar.current
        let now   = Date()
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year,  from: now)

        let receipts: [Receipt]
        if let uid = userId, !uid.isEmpty {
            let savedReceipts = (try? await receiptService.fetchReceipts(userId: uid, month: month, year: year)) ?? []
            receipts = Receipt.withMockReceipts(savedReceipts)
        } else {
            receipts = Receipt.mockReceipts()
        }

        buildMonthly(receipts: receipts, month: month, year: year)
        buildShared(receipts: receipts)
    }


    func buildMonthly(receipts: [Receipt], month: Int, year: Int) {
        let cal = Calendar.current
        let items = receipts.filter {
            let c = cal.dateComponents([.month, .year], from: $0.date)
            return c.month == month && c.year == year
        }
        monthlyTotal = items.reduce(0) { $0 + abs($1.amount) }
        monthlyWeekly = weeklyBreakdown(items: items, month: month, year: year)
        monthlyCategories = categoryBreakdown(items: items, total: monthlyTotal)
    }

    func buildShared(receipts: [Receipt]) {
        let splitReceipts = receipts.filter { $0.hasSplit }
        sharedTotal  = splitService.totalUserShare(in: splitReceipts)
        othersPaid   = splitService.totalPaidByOthers(in: splitReceipts)

        let cal   = Calendar.current
        let now   = Date()
        let month = cal.component(.month, from: now)
        let year  = cal.component(.year,  from: now)

        let monthlyShared = splitReceipts.filter {
            let c = cal.dateComponents([.month, .year], from: $0.date)
            return c.month == month && c.year == year
        }
        sharedWeekly = weeklyBreakdown(items: monthlyShared, month: month, year: year)

        let categorySource = monthlyShared.isEmpty ? splitReceipts : monthlyShared
        let total = categorySource.reduce(0) { $0 + abs($1.amount) }
        sharedCategories = categoryBreakdown(items: categorySource, total: total > 0 ? total : sharedTotal)
    }

    private func weeklyBreakdown(items: [Receipt], month: Int, year: Int) -> [WeeklySpend] {
        let cal = Calendar.current
        var weeks = [1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0]
        for r in items {
            let day  = cal.component(.day, from: r.date)
            let week = min((day - 1) / 7 + 1, 4)
            weeks[week, default: 0] += abs(r.amount)
        }
        return (1...4).map { WeeklySpend(label: "W\($0)", amount: weeks[$0] ?? 0) }
    }

    private func categoryBreakdown(items: [Receipt], total: Double) -> [CategoryExpense] {
        var catMap: [ReceiptCategory: Double] = [:]
        for r in items { catMap[r.category, default: 0] += abs(r.amount) }
        return catMap
            .sorted { $0.value > $1.value }
            .map { CategoryExpense(category: $0.key, amount: $0.value, total: total) }
    }
}
