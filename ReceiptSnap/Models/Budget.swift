import Foundation

struct Budget: Identifiable, Equatable, Codable {

    let id: UUID
    var userId: String?            
    let monthlyLimit: Double
    var currentSpending: Double
    let period: String              
    let month: Int                  
    let year: Int                   
    var alertEnabled: Bool          
    var alertThreshold: Double     
    let createdAt: Date

    init(
        id: UUID            = UUID(),
        userId: String?     = nil,
        monthlyLimit: Double,
        currentSpending: Double,
        period: String,
        alertEnabled: Bool  = true,
        alertThreshold: Double = 0.80,
        createdAt: Date     = Date()
    ) {
        self.id              = id
        self.userId          = userId
        self.monthlyLimit    = monthlyLimit
        self.currentSpending = currentSpending
        self.period          = period
        self.alertEnabled    = alertEnabled
        self.alertThreshold  = alertThreshold
        self.createdAt       = createdAt

     
        let comps = period.split(separator: " ")
        let cal   = Calendar.current
        if comps.count == 2,
           let parsedDate = DateFormatter.monthYear.date(from: period) {
            self.month = cal.component(.month, from: parsedDate)
            self.year  = cal.component(.year,  from: parsedDate)
        } else {
            let now    = Date()
            self.month = cal.component(.month, from: now)
            self.year  = cal.component(.year,  from: now)
        }
    }


    var remaining: Double {
        monthlyLimit - currentSpending
    }

    var percentConsumed: Double {
        min(currentSpending / max(monthlyLimit, 1), 1.0)
    }

    var isOverBudget: Bool {
        currentSpending > monthlyLimit
    }

    var hasReachedAlertThreshold: Bool {
        alertEnabled && percentConsumed >= alertThreshold && !isOverBudget
    }

    var statusText: String {
        isOverBudget ? "Budget exceeded" : "You're within budget"
    }

    var savingsRate: Double {
        guard monthlyLimit > 0 else { return 0 }
        return max(0, min(remaining / monthlyLimit, 1.0))
    }


    static func mock() -> Budget { MockData.budget }
}


private extension DateFormatter {
    static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
}
