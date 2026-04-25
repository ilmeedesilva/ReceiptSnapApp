import Foundation


enum WeekStatus: String, Codable {
    case active    = "Collecting receipts"
    case finalized = "Finalized"
}

struct DailyAmount: Identifiable, Equatable {
    let id     = UUID()
    let day:    String   
    let amount: Double
}

struct CategorySpend: Identifiable, Equatable {
    let id:             UUID   = UUID()
    let name:           String
    let icon:           String 
    let amount:         Double
    let totalSpent:     Double
    let colorHex:       String

    var fraction: Double    { totalSpent > 0 ? min(amount / totalSpent, 1.0) : 0 }
    var percentText: String { "\(Int(fraction * 100))% of total" }
}

struct HighValueItem: Identifiable, Equatable {
    let id:             UUID   = UUID()
    let name:           String
    let subtitle:       String 
    let amount:         Double
}

struct WeeklyReportData: Identifiable, Hashable {
    let id:             UUID   = UUID()
    let dateRange:      String  
    let year:           String  
    let status:         WeekStatus
    let receiptCount:   Int
    let totalSpent:     Double
    let vsLastWeek:     Double? 
    let vsLastWeekAmount: Double?
    let dailySpending:  [DailyAmount]
    let topCategories:  [CategorySpend]
    let highValueItems: [HighValueItem]

    var fullDateRange:  String { "\(dateRange), \(year)" }
    var displayStatus:  String { status.rawValue }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: WeeklyReportData, r: WeeklyReportData) -> Bool { l.id == r.id }


    static func mockWeeks() -> [WeeklyReportData] {
        let cal = Calendar.current
        let now = Date()
        let f   = DateFormatter(); f.dateFormat = "MMM d"
        let fY  = DateFormatter(); fY.dateFormat = "yyyy"

        func weekRange(weeksAgo: Int) -> (label: String, year: String) {

            var comps  = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            comps.weekday = 2
            let monday = cal.date(from: comps).flatMap {
                cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: $0)
            } ?? now
            let sunday = cal.date(byAdding: .day, value: 6, to: monday) ?? monday
            return ("\(f.string(from: monday)) - \(f.string(from: sunday))", fY.string(from: monday))
        }

        let w0 = weekRange(weeksAgo: 0)
        let w1 = weekRange(weeksAgo: 1)
        let w2 = weekRange(weeksAgo: 2)
        let w3 = weekRange(weeksAgo: 3)
        let w4 = weekRange(weeksAgo: 4)

        return [
            WeeklyReportData(
                dateRange: w0.label, year: w0.year, status: .active,
                receiptCount: 9, totalSpent: 487.30, vsLastWeek: nil, vsLastWeekAmount: nil,
                dailySpending: Self.sampleDaily([0, 55, 95, 140, 72, 105, 20]),
                topCategories: Self.sampleCategories(total: 487.30),
                highValueItems: Self.sampleItems()
            ),
            WeeklyReportData(
                dateRange: w1.label, year: w1.year, status: .finalized,
                receiptCount: 14, totalSpent: 892.20, vsLastWeek: -12, vsLastWeekAmount: -122.0,
                dailySpending: Self.sampleDaily([90, 110, 200, 150, 180, 100, 62]),
                topCategories: Self.sampleCategories(total: 892.20),
                highValueItems: Self.sampleItems()
            ),
            WeeklyReportData(
                dateRange: w2.label, year: w2.year, status: .finalized,
                receiptCount: 22, totalSpent: 1_204.15, vsLastWeek: 8, vsLastWeekAmount: 89.5,
                dailySpending: Self.sampleDaily([120, 200, 160, 220, 190, 180, 134]),
                topCategories: Self.sampleCategories(total: 1_204.15),
                highValueItems: Self.sampleItems()
            ),
            WeeklyReportData(
                dateRange: w3.label, year: w3.year, status: .finalized,
                receiptCount: 18, totalSpent: 650.00, vsLastWeek: -3, vsLastWeekAmount: -20.0,
                dailySpending: Self.sampleDaily([80, 100, 90, 110, 130, 80, 60]),
                topCategories: Self.sampleCategories(total: 650.00),
                highValueItems: Self.sampleItems()
            ),
            WeeklyReportData(
                dateRange: w4.label, year: w4.year, status: .finalized,
                receiptCount: 12, totalSpent: 912.40, vsLastWeek: 5, vsLastWeekAmount: 43.0,
                dailySpending: Self.sampleDaily([100, 150, 180, 140, 160, 120, 62]),
                topCategories: Self.sampleCategories(total: 912.40),
                highValueItems: Self.sampleItems()
            ),
        ]
    }

    private static func sampleDaily(_ amounts: [Double]) -> [DailyAmount] {
        zip(["M","T","W","T","F","S","S"], amounts).map { DailyAmount(day: $0, amount: $1) }
    }

    private static func sampleCategories(total: Double) -> [CategorySpend] {
        [
            CategorySpend(name: "Groceries",     icon: "cart.fill",      amount: total * 0.36, totalSpent: total, colorHex: "3B82F6"),
            CategorySpend(name: "Travel",        icon: "airplane",       amount: total * 0.25, totalSpent: total, colorHex: "F97316"),
            CategorySpend(name: "Entertainment", icon: "sparkles",       amount: total * 0.15, totalSpent: total, colorHex: "8B5CF6"),
        ]
    }

    private static func sampleItems() -> [HighValueItem] {
        [
            HighValueItem(name: "Apple Store", subtitle: "May 15 • Electronics", amount: 599.00),
            HighValueItem(name: "Home Depot",  subtitle: "May 12 • Home",        amount: 242.15),
        ]
    }
}


struct MonthlyCategory: Identifiable, Equatable {
    let id       = UUID()
    let name:     String
    let amount:   Double
    let total:    Double
    let trend:    String   
    let colorHex: String

    var fraction: Double { total > 0 ? min(amount / total, 1.0) : 0 }
}

struct MonthlyInsights: Equatable {
    let mostExpensiveDay:       String
    let mostExpensiveDayAmount: Double
    let topCategory:            String
    let topCategoryPercent:     Int
}

struct MonthlyReportData: Identifiable, Hashable {
    let id                = UUID()
    let month:            String   
    let year:             String  
    let totalSpent:       Double
    let avgPerDay:        Double
    let receiptCount:     Int
    let budgetUsedPercent: Int
    let categories:       [MonthlyCategory]
    let insights:         MonthlyInsights

    var displayLabel: String { "\(month) \(year)" }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: MonthlyReportData, r: MonthlyReportData) -> Bool { l.id == r.id }



    static func mockMonths() -> [MonthlyReportData] {
        [
           
            MonthlyReportData(
                month: "April", year: "2026",
                totalSpent: 1_893.81, avgPerDay: 63.13, receiptCount: 30, budgetUsedPercent: 76,
                categories: [
                    MonthlyCategory(name: "Food & Drinks", amount:   528.70, total: 1_893.81, trend: "12% more than last month",  colorHex: "8B5CF6"),
                    MonthlyCategory(name: "Shopping",      amount:   413.49, total: 1_893.81, trend: "Stable vs last month",      colorHex: "3B82F6"),
                    MonthlyCategory(name: "Bills",         amount:   268.36, total: 1_893.81, trend: "Fixed monthly cost",        colorHex: "F59E0B"),
                    MonthlyCategory(name: "Transport",     amount:   181.50, total: 1_893.81, trend: "8% less than last month",   colorHex: "10B981"),
                    MonthlyCategory(name: "Other",         amount:   501.76, total: 1_893.81, trend: "Includes Airbnb stay",      colorHex: "EF4444"),
                ],
                insights: MonthlyInsights(mostExpensiveDay: "Apr 1st", mostExpensiveDayAmount: 395.00, topCategory: "Food & Drinks", topCategoryPercent: 28)
            ),

            MonthlyReportData(
                month: "March", year: "2026",
                totalSpent: 2_134.79, avgPerDay: 68.87, receiptCount: 35, budgetUsedPercent: 85,
                categories: [
                    MonthlyCategory(name: "Shopping",      amount:   820.00, total: 2_134.79, trend: "18% more than last month",  colorHex: "3B82F6"),
                    MonthlyCategory(name: "Food & Drinks", amount:   612.30, total: 2_134.79, trend: "Stable vs last month",      colorHex: "8B5CF6"),
                    MonthlyCategory(name: "Bills",         amount:   352.49, total: 2_134.79, trend: "Fixed monthly cost",        colorHex: "F59E0B"),
                    MonthlyCategory(name: "Transport",     amount:   350.00, total: 2_134.79, trend: "12% more than last month",  colorHex: "10B981"),
                ],
                insights: MonthlyInsights(mostExpensiveDay: "Mar 22nd", mostExpensiveDayAmount: 420.00, topCategory: "Shopping", topCategoryPercent: 38)
            ),

            MonthlyReportData(
                month: "February", year: "2026",
                totalSpent: 1_980.45, avgPerDay: 70.73, receiptCount: 29, budgetUsedPercent: 90,
                categories: [
                    MonthlyCategory(name: "Food & Drinks", amount:   680.00, total: 1_980.45, trend: "Stable vs last month",      colorHex: "8B5CF6"),
                    MonthlyCategory(name: "Shopping",      amount:   595.45, total: 1_980.45, trend: "5% less than last month",   colorHex: "3B82F6"),
                    MonthlyCategory(name: "Bills",         amount:   380.00, total: 1_980.45, trend: "Fixed monthly cost",        colorHex: "F59E0B"),
                    MonthlyCategory(name: "Transport",     amount:   325.00, total: 1_980.45, trend: "Stable vs last month",      colorHex: "10B981"),
                ],
                insights: MonthlyInsights(mostExpensiveDay: "Feb 14th", mostExpensiveDayAmount: 390.00, topCategory: "Food & Drinks", topCategoryPercent: 34)
            ),

            MonthlyReportData(
                month: "January", year: "2026",
                totalSpent: 2_310.00, avgPerDay: 74.52, receiptCount: 41, budgetUsedPercent: 115,
                categories: [
                    MonthlyCategory(name: "Shopping",      amount:   980.00, total: 2_310.00, trend: "New Year shopping spike",   colorHex: "3B82F6"),
                    MonthlyCategory(name: "Food & Drinks", amount:   630.00, total: 2_310.00, trend: "10% more than last month",  colorHex: "8B5CF6"),
                    MonthlyCategory(name: "Bills",         amount:   410.00, total: 2_310.00, trend: "Fixed monthly cost",        colorHex: "F59E0B"),
                    MonthlyCategory(name: "Transport",     amount:   290.00, total: 2_310.00, trend: "Stable vs last month",      colorHex: "10B981"),
                ],
                insights: MonthlyInsights(mostExpensiveDay: "Jan 2nd",  mostExpensiveDayAmount: 510.00, topCategory: "Shopping",     topCategoryPercent: 42)
            ),

            MonthlyReportData(
                month: "December", year: "2025",
                totalSpent: 2_875.50, avgPerDay: 92.76, receiptCount: 47, budgetUsedPercent: 96,
                categories: [
                    MonthlyCategory(name: "Shopping",      amount: 1_250.50, total: 2_875.50, trend: "Holiday season spike",      colorHex: "3B82F6"),
                    MonthlyCategory(name: "Food & Drinks", amount:   750.00, total: 2_875.50, trend: "20% more than last month",  colorHex: "8B5CF6"),
                    MonthlyCategory(name: "Bills",         amount:   475.00, total: 2_875.50, trend: "Fixed monthly cost",        colorHex: "F59E0B"),
                    MonthlyCategory(name: "Transport",     amount:   400.00, total: 2_875.50, trend: "Holiday travel",            colorHex: "10B981"),
                ],
                insights: MonthlyInsights(mostExpensiveDay: "Dec 24th", mostExpensiveDayAmount: 680.00, topCategory: "Shopping",     topCategoryPercent: 44)
            ),

            MonthlyReportData(
                month: "November", year: "2025",
                totalSpent: 1_650.00, avgPerDay: 55.00, receiptCount: 26, budgetUsedPercent: 83,
                categories: [
                    MonthlyCategory(name: "Food & Drinks", amount:   540.00, total: 1_650.00, trend: "Stable vs last month",      colorHex: "8B5CF6"),
                    MonthlyCategory(name: "Shopping",      amount:   480.00, total: 1_650.00, trend: "Black Friday deals",        colorHex: "3B82F6"),
                    MonthlyCategory(name: "Bills",         amount:   340.00, total: 1_650.00, trend: "Fixed monthly cost",        colorHex: "F59E0B"),
                    MonthlyCategory(name: "Transport",     amount:   290.00, total: 1_650.00, trend: "Stable vs last month",      colorHex: "10B981"),
                ],
                insights: MonthlyInsights(mostExpensiveDay: "Nov 28th", mostExpensiveDayAmount: 340.00, topCategory: "Food & Drinks", topCategoryPercent: 33)
            ),
        ]
    }

    static func mock(for month: String) -> MonthlyReportData? {
        mockMonths().first { $0.month == month || $0.displayLabel == month }
    }
}
struct MonthPickerItem: Identifiable, Equatable {
    var id:            String { "\(year)-\(month)" }
    let month:         String
    let shortMonth:    String
    let year:          Int
    let totalSpent:    Double
    let receiptCount:  Int
    let hasData:       Bool
}
