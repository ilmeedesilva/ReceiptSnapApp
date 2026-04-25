
import Foundation

struct SpendingCategory: Identifiable, Equatable {

    let id: UUID
    let category:    ReceiptCategory
    let totalAmount: Double          // renamed from `amount` to avoid ambiguity
    let percentage:  Double          // fraction 0–1 of total monthly spend

    init(id: UUID = UUID(), category: ReceiptCategory,
         totalAmount: Double, percentage: Double = 0) {
        self.id          = id
        self.category    = category
        self.totalAmount = totalAmount
        self.percentage  = percentage
    }

    // MARK: - Backward-compat alias (used by UI components)
    var amount: Double { totalAmount }

    // Convenience pass-throughs from the category enum
    var label: String      { category.rawValue  }
    var shortLabel: String { category.shortLabel }
    var icon: String       { category.icon       }

    // MARK: - Mock

    static func mockCategories() -> [SpendingCategory] {
        let total = 485.0
        return [
            SpendingCategory(category: .food,      totalAmount: 120.00, percentage: 120/total),
            SpendingCategory(category: .transport, totalAmount:  48.50, percentage: 48.5/total),
            SpendingCategory(category: .shopping,  totalAmount:  90.00, percentage: 90/total),
            SpendingCategory(category: .bills,     totalAmount:  85.00, percentage: 85/total),
            SpendingCategory(category: .other,     totalAmount: 141.50, percentage: 141.5/total),
        ]
    }
}
