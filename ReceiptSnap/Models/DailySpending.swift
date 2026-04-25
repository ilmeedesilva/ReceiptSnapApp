import Foundation

struct DailySpending: Identifiable {
    let id: UUID
    let dayLabel: String  
    let amount: Double

    init(id: UUID = UUID(), dayLabel: String, amount: Double) {
        self.id       = id
        self.dayLabel = dayLabel
        self.amount   = amount
    }


    static func mockWeek() -> [DailySpending] {
        [
            DailySpending(dayLabel: "M", amount: 42.0),
            DailySpending(dayLabel: "T", amount: 18.5),
            DailySpending(dayLabel: "W", amount: 75.0),
            DailySpending(dayLabel: "T", amount: 55.0),
            DailySpending(dayLabel: "F", amount: 90.0),
            DailySpending(dayLabel: "S", amount: 30.0),
            DailySpending(dayLabel: "S", amount: 22.0),
        ]
    }
}
