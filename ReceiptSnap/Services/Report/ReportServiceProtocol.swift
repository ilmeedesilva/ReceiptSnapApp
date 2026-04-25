
import Foundation


protocol ReportServiceProtocol: AnyObject {
    func weeklyReport(receipts: [Receipt], weekStart: Date) -> WeeklyReportData
    func monthlyReport(receipts: [Receipt], month: Int, year: Int,
                       budget: Budget?) -> MonthlyReportData
    func insightStrings(receipts: [Receipt], month: Int, year: Int) -> [String]
}


final class ReportService: ReportServiceProtocol {

    private let calendar = Calendar.current

    // MARK: - Weekly report

    func weeklyReport(receipts: [Receipt], weekStart: Date) -> WeeklyReportData {
        let weekEnd   = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let weekItems = receipts.filter { $0.date >= weekStart && $0.date < weekEnd }
        let total     = weekItems.reduce(0.0) { $0 + abs($1.amount) }

        // Daily totals — Mon(0)…Sun(6)
        var dayAmounts = Array(repeating: 0.0, count: 7)
        for r in weekItems {
            let weekday = calendar.component(.weekday, from: r.date)
            let idx = (weekday + 5) % 7   // Sunday=1 → idx 6, Monday=2 → idx 0
            dayAmounts[idx] += abs(r.amount)
        }
        let dailySpending: [DailyAmount] = zip(["M","T","W","T","F","S","S"], dayAmounts)
            .map { DailyAmount(day: $0, amount: $1) }

        // Category breakdown
        var catMap: [ReceiptCategory: Double] = [:]
        for r in weekItems { catMap[r.category, default: 0] += abs(r.amount) }
        let topCategories: [CategorySpend] = catMap
            .sorted { $0.value > $1.value }
            .map { cat, amount in
                CategorySpend(
                    name:      cat.rawValue,
                    icon:      cat.icon,
                    amount:    amount,
                    totalSpent: total,
                    colorHex:  cat.colorHex
                )
            }

        // High-value items (top 5)
        let highValueItems: [HighValueItem] = weekItems
            .sorted { abs($0.amount) > abs($1.amount) }
            .prefix(5)
            .map { r in
                let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
                let subtitle = "\(fmt.string(from: r.date)) • \(r.category.rawValue)"
                return HighValueItem(name: r.title, subtitle: subtitle, amount: abs(r.amount))
            }

        // % change vs previous week
        let prevStart  = calendar.date(byAdding: .day, value: -7, to: weekStart) ?? weekStart
        let prevTotal  = receipts
            .filter { $0.date >= prevStart && $0.date < weekStart }
            .reduce(0.0) { $0 + abs($1.amount) }
        let vsLastWeek: Double?       = prevTotal > 0 ? (total - prevTotal) / prevTotal * 100 : nil
        let vsLastWeekAmount: Double? = prevTotal > 0 ? total - prevTotal : nil

        // Format date range & year
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let weekEnd6 = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        let dateRange = "\(fmt.string(from: weekStart)) - \(fmt.string(from: weekEnd6))"
        fmt.dateFormat = "yyyy"
        let year = fmt.string(from: weekStart)

        return WeeklyReportData(
            dateRange:       dateRange,
            year:            year,
            status:          .finalized,
            receiptCount:    weekItems.count,
            totalSpent:      total,
            vsLastWeek:      vsLastWeek,
            vsLastWeekAmount: vsLastWeekAmount,
            dailySpending:   dailySpending,
            topCategories:   topCategories,
            highValueItems:  highValueItems
        )
    }

    // MARK: - Monthly report

    func monthlyReport(receipts: [Receipt], month: Int, year: Int,
                       budget: Budget?) -> MonthlyReportData {
        let monthItems = receipts.filter {
            let c = calendar.dateComponents([.month, .year], from: $0.date)
            return c.month == month && c.year == year
        }
        let total      = monthItems.reduce(0.0) { $0 + abs($1.amount) }
        let count      = monthItems.count
        let daysInMonth: Int = {
            var comps  = DateComponents(year: year, month: month)
            let date   = calendar.date(from: comps) ?? Date()
            return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        }()
        let avgPerDay  = daysInMonth > 0 ? total / Double(daysInMonth) : 0

        // Category breakdown — compare to previous month for trend text
        var catMap: [ReceiptCategory: Double] = [:]
        for r in monthItems { catMap[r.category, default: 0] += abs(r.amount) }

        let prevMonth  = month == 1 ? 12 : month - 1
        let prevYear   = month == 1 ? year - 1 : year
        let prevItems  = receipts.filter {
            let c = calendar.dateComponents([.month, .year], from: $0.date)
            return c.month == prevMonth && c.year == prevYear
        }
        var prevCatMap: [ReceiptCategory: Double] = [:]
        for r in prevItems { prevCatMap[r.category, default: 0] += abs(r.amount) }

        let categories: [MonthlyCategory] = catMap
            .sorted { $0.value > $1.value }
            .map { cat, amount in
                let prevAmt = prevCatMap[cat] ?? 0
                let trend: String
                if prevAmt == 0 {
                    trend = "New this month"
                } else {
                    let pct = Int(((amount - prevAmt) / prevAmt) * 100)
                    if abs(pct) < 3  { trend = "Stable vs last month" }
                    else if pct > 0  { trend = "\(pct)% more than last month" }
                    else             { trend = "\(abs(pct))% less than last month" }
                }
                return MonthlyCategory(
                    name:     cat.rawValue,
                    amount:   amount,
                    total:    total,
                    trend:    trend,
                    colorHex: cat.colorHex
                )
            }

        // Budget usage
        let budgetPct: Int = budget.map {
            Int(min($0.currentSpending / max($0.monthlyLimit, 1), 1.0) * 100)
        } ?? 0

        // Insights
        let topCat        = catMap.max { $0.value < $1.value }
        let topCatPct     = total > 0 ? Int((topCat?.value ?? 0) / total * 100) : 0
        let topCatName    = topCat?.key.rawValue ?? "—"

        // Most expensive day
        var dayMap: [Int: Double] = [:]
        for r in monthItems {
            let day = calendar.component(.day, from: r.date)
            dayMap[day, default: 0] += abs(r.amount)
        }
        let topDay        = dayMap.max { $0.value < $1.value }
        let topDayLabel   = topDay.map { "\(ordinal($0.key))" } ?? "—"
        let topDayAmount  = topDay?.value ?? 0

        let monthNames = ["Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"]
        let monthName  = monthNames[max(0, month - 1)]

        return MonthlyReportData(
            month:            monthName,
            year:             "\(year)",
            totalSpent:       total,
            avgPerDay:        avgPerDay,
            receiptCount:     count,
            budgetUsedPercent: budgetPct,
            categories:       categories,
            insights:         MonthlyInsights(
                mostExpensiveDay:       topDayLabel,
                mostExpensiveDayAmount: topDayAmount,
                topCategory:            topCatName,
                topCategoryPercent:     topCatPct
            )
        )
    }

    // MARK: - Insights (plain strings for UI cards)

    func insightStrings(receipts: [Receipt], month: Int, year: Int) -> [String] {
        let items = receipts.filter {
            let c = calendar.dateComponents([.month, .year], from: $0.date)
            return c.month == month && c.year == year
        }
        guard !items.isEmpty else { return [] }

        var results: [String] = []

        var catMap: [ReceiptCategory: Double] = [:]
        for r in items { catMap[r.category, default: 0] += abs(r.amount) }
        if let top = catMap.max(by: { $0.value < $1.value }) {
            results.append("Biggest category: \(top.key.rawValue) ($\(String(format: "%.0f", top.value))).")
        }

        if let priciest = items.max(by: { abs($0.amount) < abs($1.amount) }) {
            results.append("Largest expense: \(priciest.title) at \(priciest.formattedAmount).")
        }

        var dayMap: [Int: Double] = [:]
        for r in items {
            let day = calendar.component(.day, from: r.date)
            dayMap[day, default: 0] += abs(r.amount)
        }
        if let topDay = dayMap.max(by: { $0.value < $1.value }) {
            results.append("Highest spending day: \(ordinal(topDay.key)) ($\(String(format: "%.0f", topDay.value))).")
        }

        return results
    }

    // MARK: - Private helpers

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n % 100 {
        case 11, 12, 13: suffix = "th"
        default:
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}
