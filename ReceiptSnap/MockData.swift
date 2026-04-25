import Foundation

enum MockData {

    // MARK: - Receipts
    // Add, remove, or change any of these to customise the demo.

    static var receipts: [Receipt] {
        let cal = Calendar.current
        let now = Date()

        func daysAgo(_ n: Int, hour: Int = 12, minute: Int = 0) -> Date {
            var c = cal.dateComponents([.year, .month, .day],
                                       from: cal.date(byAdding: .day, value: -n, to: now) ?? now)
            c.hour = hour; c.minute = minute
            return cal.date(from: c) ?? now
        }

        // Helper: offset within current month (day 1 = start of month)
        let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
        func monthDay(_ d: Int, hour: Int = 12, minute: Int = 0) -> Date {
            var c = cal.dateComponents([.year, .month, .day], from: monthStart)
            c.day = d; c.hour = hour; c.minute = minute
            return cal.date(from: c) ?? now
        }

        return [
            // ── This week (recent) ────────────────────────────────────────
            Receipt(title: "Starbucks Coffee",    category: .food,      date: daysAgo(0, hour: 8,  minute: 30), amount: -12.50,
                    isFavorite: false, tags: ["coffee"]),
            Receipt(title: "Uber Ride",            category: .transport, date: daysAgo(1, hour: 9,  minute: 0),  amount: -24.80),
            Receipt(title: "Amazon Order",         category: .shopping,  date: daysAgo(2, hour: 14, minute: 15), amount: -89.99,
                    isFavorite: true, tags: ["tech"]),
            Receipt(title: "Netflix Subscription", category: .bills,     date: daysAgo(3, hour: 10, minute: 0),  amount: -15.99),

            // ── Current-month Week 1 (days 1–7) ───────────────────────────
            Receipt(title: "Lunch with Alex",      category: .food,      date: monthDay(1, hour: 12, minute: 30), amount: -60.00,
                    isFavorite: true,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Alex Rivera",
                                             splitType: .equal, yourAmount: 30.00, otherAmount: 30.00)),
            Receipt(title: "Airbnb Stay",          category: .other,     date: monthDay(1, hour: 15, minute: 0),  amount: -240.00,
                    isFavorite: true,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Sarah Johnson",
                                             splitType: .equal, yourAmount: 120.00, otherAmount: 120.00)),
            Receipt(title: "Grocery Run",          category: .food,      date: monthDay(1, hour: 11, minute: 0),  amount: -85.60,
                    tags: ["groceries"],
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Jake Smith",
                                             splitType: .custom, yourAmount: 45.00, otherAmount: 40.60)),
            Receipt(title: "Coffee Shop",          category: .food,      date: monthDay(3, hour: 8,  minute: 15), amount: -9.80),
            Receipt(title: "Internet Bill",        category: .bills,     date: monthDay(4, hour: 9,  minute: 0),  amount: -59.99),
            Receipt(title: "Uber to Airport",      category: .transport, date: monthDay(5, hour: 6,  minute: 45), amount: -38.50),
            Receipt(title: "ASOS Order",           category: .shopping,  date: monthDay(6, hour: 14, minute: 30), amount: -112.00,
                    tags: ["clothing"]),
            Receipt(title: "Sushi Dinner",         category: .food,      date: monthDay(7, hour: 19, minute: 0),  amount: -76.40,
                    isFavorite: true),

            // ── Current-month Week 2 (days 8–14) ──────────────────────────
            Receipt(title: "Pharmacy",             category: .other,     date: monthDay(9, hour: 11, minute: 0),  amount: -28.75),
            Receipt(title: "Gas Station",          category: .transport, date: monthDay(10, hour: 7, minute: 30), amount: -62.00),
            Receipt(title: "Supermarket",          category: .food,      date: monthDay(11, hour: 10, minute: 30), amount: -94.30,
                    tags: ["groceries"]),
            Receipt(title: "Movie Night",          category: .other,     date: monthDay(12, hour: 20, minute: 0),  amount: -36.00,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Alex Rivera",
                                             splitType: .equal, yourAmount: 18.00, otherAmount: 18.00)),
            Receipt(title: "Phone Bill",           category: .bills,     date: monthDay(13, hour: 9,  minute: 0),  amount: -45.00),
            Receipt(title: "Home Goods",           category: .shopping,  date: monthDay(14, hour: 15, minute: 0),  amount: -88.50,
                    tags: ["home"]),

            // ── Current-month Week 3 (days 15–21) ─────────────────────────
            Receipt(title: "Pizza Delivery",       category: .food,      date: monthDay(16, hour: 19, minute: 30), amount: -32.90),
            Receipt(title: "Train Tickets",        category: .transport, date: monthDay(17, hour: 8,  minute: 0),  amount: -44.00,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Sarah Johnson",
                                             splitType: .equal, yourAmount: 22.00, otherAmount: 22.00)),
            Receipt(title: "Gym Membership",       category: .bills,     date: monthDay(18, hour: 9,  minute: 0),  amount: -45.00),
            Receipt(title: "Nike Store",           category: .shopping,  date: monthDay(19, hour: 13, minute: 0),  amount: -145.00,
                    isFavorite: true, tags: ["clothing", "sport"]),
            Receipt(title: "Brunch with Friends",  category: .food,      date: monthDay(20, hour: 11, minute: 0),  amount: -55.00,
                    isFavorite: true),
            Receipt(title: "Parking Fee",          category: .transport, date: monthDay(21, hour: 18, minute: 0),  amount: -15.00),

            // ── Current-month Week 4 (days 22–28) ─────────────────────────
            Receipt(title: "Streaming Bundle",     category: .bills,     date: monthDay(23, hour: 10, minute: 0),  amount: -25.97),
            Receipt(title: "Weekly Groceries",     category: .food,      date: monthDay(24, hour: 11, minute: 0),  amount: -110.20,
                    tags: ["groceries"]),
            Receipt(title: "Tech Accessories",     category: .shopping,  date: monthDay(25, hour: 14, minute: 0),  amount: -67.99,
                    tags: ["tech"]),
            Receipt(title: "Restaurant Dinner",    category: .food,      date: monthDay(26, hour: 20, minute: 0),  amount: -89.50,
                    isFavorite: true,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Jake Smith",
                                             splitType: .equal, yourAmount: 44.75, otherAmount: 44.75)),
            Receipt(title: "Taxi Ride",            category: .transport, date: monthDay(27, hour: 23, minute: 30), amount: -22.00),
            Receipt(title: "Electricity Bill",     category: .bills,     date: monthDay(28, hour: 9,  minute: 0),  amount: -92.40),

            // ── Last week ──────────────────────────────────────────────────
            Receipt(title: "Whole Foods",          category: .food,      date: daysAgo(8,  hour: 11, minute: 0),  amount: -67.30,
                    tags: ["groceries"]),
            Receipt(title: "Target",               category: .shopping,  date: daysAgo(9,  hour: 15, minute: 30), amount: -134.50,
                    tags: ["home"]),
            Receipt(title: "Electric Bill",        category: .bills,     date: daysAgo(11, hour: 9,  minute: 0),  amount: -89.45),
            Receipt(title: "Cinema Tickets",       category: .other,     date: daysAgo(12, hour: 19, minute: 0),  amount: -32.00,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Jake Smith",
                                             splitType: .equal, yourAmount: 16.00, otherAmount: 16.00)),

            // ── Older ──────────────────────────────────────────────────────
            Receipt(title: "Shell Gas Station",    category: .transport, date: daysAgo(15, hour: 8,  minute: 0),  amount: -55.00),
            Receipt(title: "Restaurant Dinner",    category: .food,      date: daysAgo(17, hour: 20, minute: 0),  amount: -120.00,
                    isFavorite: true,
                    splitDetail: SplitDetail(isEnabled: true, splitWithName: "Sarah Johnson",
                                             splitType: .equal, yourAmount: 60.00, otherAmount: 60.00)),
            Receipt(title: "Gym Membership",       category: .bills,     date: daysAgo(21, hour: 9,  minute: 0),  amount: -45.00),
            Receipt(title: "Apple Store",          category: .shopping,  date: daysAgo(22, hour: 14, minute: 0),  amount: -299.00,
                    isFavorite: true, tags: ["tech", "work"]),
            Receipt(title: "Metro Transit Pass",   category: .transport, date: daysAgo(28, hour: 7,  minute: 30), amount: -35.00),
            Receipt(title: "Spotify Premium",      category: .bills,     date: daysAgo(35, hour: 10, minute: 0),  amount: -9.99),
            Receipt(title: "Supermarket Run",      category: .food,      date: daysAgo(40, hour: 11, minute: 0),  amount: -145.00,
                    tags: ["groceries"]),
        ]
    }

    // MARK: - Budget (current month)

    static var budget: Budget {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        // Spending: sum of all current-month receipts ≈ 1894
        return Budget(
            monthlyLimit:    2_500,
            currentSpending: 1_893.81,
            period:          f.string(from: Date()),
            alertEnabled:    true,
            alertThreshold:  0.80
        )
    }

    // MARK: - Notifications

    static var notifications: [AppNotification] {
        let now = Date()
        func ago(_ secs: TimeInterval) -> Date { now.addingTimeInterval(-secs) }

        return [
            AppNotification(type: .budgetFeedback,
                            title:   "You're on track! 🎉",
                            message: "You've used 40% of your monthly budget. Keep it up!",
                            timestamp: ago(10 * 60), isRead: false),
            AppNotification(type: .weeklyReport,
                            title:   "Weekly Spending Report Ready",
                            message: "Your weekly breakdown is ready. You spent $338.79 this week.",
                            timestamp: ago(26 * 3600), isRead: false),
            AppNotification(type: .budgetAlert,
                            title:   "Budget Alert: 80% Used",
                            message: "You've used $2,000 of your $2,500 monthly budget.",
                            timestamp: ago(3 * 86_400), isRead: false),
            AppNotification(type: .receiptReminder,
                            title:   "Don't forget to log expenses",
                            message: "Tap to add today's receipts before they're forgotten.",
                            timestamp: ago(5 * 86_400), isRead: true),
            AppNotification(type: .locationReminder,
                            title:   "Expense spotted near Starbucks",
                            message: "You were near Starbucks on Pacific Ave. Add a receipt?",
                            timestamp: ago(7 * 86_400), isRead: true),
            AppNotification(type: .dailyReminder,
                            title:   "Daily Reminder",
                            message: "Log your expenses for today and stay on budget!",
                            timestamp: ago(10 * 86_400), isRead: true),
        ]
    }
}
