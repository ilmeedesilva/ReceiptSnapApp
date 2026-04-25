
import SwiftUI
import Combine


enum ReportMode: String, CaseIterable, Identifiable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}


@MainActor
final class ReportsViewModel: ObservableObject {

    // MARK: - Published state

    @Published var reportMode:     ReportMode          = .weekly
    @Published var weeklyReports:  [WeeklyReportData]  = []
    @Published var monthlyReports: [MonthlyReportData] = []
    @Published var selectedYear:   Int                 = Calendar.current.component(.year, from: Date())
    @Published var isLoading:      Bool                = false
    @Published var errorMessage:   String?             = nil

    // MARK: - Dependencies

    private let reportService:  ReportServiceProtocol
    private let receiptService: ReceiptServiceProtocol
    private let budgetService:  BudgetServiceProtocol

    // MARK: - Init

    init(
        reportService:  ReportServiceProtocol  = ServiceLocator.shared.reportService,
        receiptService: ReceiptServiceProtocol = ServiceLocator.shared.receiptService,
        budgetService:  BudgetServiceProtocol  = ServiceLocator.shared.budgetService
    ) {
        self.reportService  = reportService
        self.receiptService = receiptService
        self.budgetService  = budgetService
    }

    // MARK: - Computed (pure — unit-testable)

    var activeWeek: WeeklyReportData? { weeklyReports.first { $0.status == .active } }
    var pastWeeks:  [WeeklyReportData] { weeklyReports.filter { $0.status == .finalized } }

    var totalMonthlySpend: Double { weeklyReports.reduce(0) { $0 + $1.totalSpent } }

    /// Fraction (0–1) of the current month's budget consumed, for the progress bar.
    var monthlyBudgetUsed: Double {
        guard let current = monthlyReports.first else { return 0 }
        return min(Double(current.budgetUsedPercent) / 100.0, 1.0)
    }

    var availableYears: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return [current - 1, current]
    }

    func monthItems(for year: Int) -> [MonthPickerItem] {
        let months = ["January","February","March","April","May","June",
                      "July","August","September","October","November","December"]
        let short  = ["Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec"]
        return months.enumerated().map { i, month in
            let data = monthlyReports.first {
                $0.month == month && $0.year == "\(year)"
            }
            return MonthPickerItem(
                month:        month,
                shortMonth:   short[i],
                year:         year,
                totalSpent:   data?.totalSpent   ?? 0,
                receiptCount: data?.receiptCount ?? 0,
                hasData:      data != nil
            )
        }
    }

    // MARK: - Load

    func loadReports(userId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        guard let uid = userId, !uid.isEmpty else {
            weeklyReports  = WeeklyReportData.mockWeeks()
            monthlyReports = MonthlyReportData.mockMonths()
            return
        }

        let cal = Calendar.current
        let now = Date()

        // Fetch 3 months of receipts for report calculations
        let threeMonthsAgo = cal.date(byAdding: .month, value: -3, to: now) ?? now
        let receipts = (try? await receiptService.fetchReceipts(userId: uid, from: threeMonthsAgo, to: now)) ?? Receipt.mockReceipts()

        // Generate last 5 weekly reports
        var weeks: [WeeklyReportData] = []
        for weekOffset in 0..<5 {
            let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: startOfWeek(now)) ?? now
            var report    = reportService.weeklyReport(receipts: receipts, weekStart: weekStart)
            // First week is always "active", rest are finalized
            if weekOffset == 0 {
                report = WeeklyReportData(
                    dateRange:        report.dateRange,
                    year:             report.year,
                    status:           .active,
                    receiptCount:     report.receiptCount,
                    totalSpent:       report.totalSpent,
                    vsLastWeek:       report.vsLastWeek,
                    vsLastWeekAmount: report.vsLastWeekAmount,
                    dailySpending:    report.dailySpending,
                    topCategories:    report.topCategories,
                    highValueItems:   report.highValueItems
                )
            }
            weeks.append(report)
        }
        weeklyReports = weeks

        // Generate monthly reports for current year
        let currentMonth = cal.component(.month, from: now)
        var months: [MonthlyReportData] = []
        for m in 1...currentMonth {
            let budget = try? await budgetService.fetchBudget(userId: uid, month: m, year: selectedYear)
            let report = reportService.monthlyReport(receipts: receipts, month: m,
                                                      year: selectedYear, budget: budget)
            months.append(report)
        }
        monthlyReports = months.reversed()   // newest first
    }

    func weeklyReport(for dateRange: String) -> WeeklyReportData? {
        weeklyReports.first { $0.dateRange == dateRange }
    }

    func monthlyReport(for displayLabel: String) -> MonthlyReportData? {
        monthlyReports.first { $0.displayLabel == displayLabel }
    }

    // MARK: - Helpers

    private func startOfWeek(_ date: Date) -> Date {
        let cal   = Calendar.current
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        comps.weekday = 2   // Monday
        return cal.date(from: comps) ?? date
    }
}
