import Foundation

struct ReportItem: Identifiable {

    let id: UUID
    let badge: String           
    let badgeIcon: String      
    let dateRange: String       
    let totalAmount: Double
    let footerText: String     
    let footerIsPositive: Bool

    init(
        id: UUID = UUID(),
        badge: String,
        badgeIcon: String,
        dateRange: String,
        totalAmount: Double,
        footerText: String,
        footerIsPositive: Bool = true
    ) {
        self.id               = id
        self.badge            = badge
        self.badgeIcon        = badgeIcon
        self.dateRange        = dateRange
        self.totalAmount      = totalAmount
        self.footerText       = footerText
        self.footerIsPositive = footerIsPositive
    }


    static func mockReports() -> [ReportItem] {
        let cal = Calendar.current
        let now = Date()
        let mf  = DateFormatter(); mf.dateFormat = "MMMM yyyy"
        let df  = DateFormatter(); df.dateFormat = "MMM d"

        let currentMonthLabel = mf.string(from: now)

        var wComps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        wComps.weekday = 2
        let monday = cal.date(from: wComps).flatMap {
            cal.date(byAdding: .weekOfYear, value: -1, to: $0)
        } ?? now
        let sunday = cal.date(byAdding: .day, value: 6, to: monday) ?? monday
        let weekLabel = "\(df.string(from: monday)) - \(df.string(from: sunday))"

        return [
            ReportItem(
                badge:            "MONTHLY REPORT",
                badgeIcon:        "arrow.up.right",
                dateRange:        currentMonthLabel,
                totalAmount:      1_893.81,
                footerText:       "+12% vs last month",
                footerIsPositive: true
            ),
            ReportItem(
                badge:            "WEEKLY REPORT",
                badgeIcon:        "calendar",
                dateRange:        weekLabel,
                totalAmount:      892.20,
                footerText:       "7 days tracked",
                footerIsPositive: true
            ),
        ]
    }
}
