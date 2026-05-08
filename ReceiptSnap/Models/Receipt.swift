import Foundation



struct Receipt: Identifiable, Equatable, Codable {

    let id: UUID
    var userId: String?             
    var title: String               
    var category: ReceiptCategory
    var date: Date
    var amount: Double             
    var notes: String
    var isFavorite: Bool
    var tags: [String]             
    var imageURL: String?          
    var splitDetail: SplitDetail?
    let createdAt: Date            
    var updatedAt: Date           

    init(
        id: UUID                  = UUID(),
        userId: String?           = nil,
        title: String,
        category: ReceiptCategory,
        date: Date,
        amount: Double,
        notes: String             = "",
        isFavorite: Bool          = false,
        tags: [String]            = [],
        imageURL: String?         = nil,
        splitDetail: SplitDetail? = nil,
        createdAt: Date           = Date(),
        updatedAt: Date           = Date()
    ) {
        self.id          = id
        self.userId      = userId
        self.title       = title
        self.category    = category
        self.date        = date
        self.amount      = amount
        self.notes       = notes
        self.isFavorite  = isFavorite
        self.tags        = tags
        self.imageURL    = imageURL
        self.splitDetail = splitDetail
        self.createdAt   = createdAt
        self.updatedAt   = updatedAt
    }


    var formattedAmount: String {
        String(format: "%@$%.2f", amount < 0 ? "-" : "+", abs(amount))
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        return f.string(from: date)
    }

    var formattedDateTime: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy • hh:mm a"
        return f.string(from: date)
    }

    var hasSplit: Bool { splitDetail?.isEnabled == true }

    var userShare: Double {
        hasSplit ? (splitDetail?.yourAmount ?? abs(amount)) : abs(amount)
    }


    static func mockReceipts() -> [Receipt] { MockData.receipts }

    static func withMockReceipts(_ savedReceipts: [Receipt]) -> [Receipt] {
        var seenIds = Set<UUID>()
        return (savedReceipts + mockReceipts())
            .filter { receipt in
                seenIds.insert(receipt.id).inserted
            }
            .sorted { lhs, rhs in
                if lhs.date == rhs.date {
                    return lhs.updatedAt > rhs.updatedAt
                }
                return lhs.date > rhs.date
            }
    }
}


enum ReceiptCategory: String, CaseIterable, Identifiable, Codable {
    case food      = "Food"
    case transport = "Transport"
    case shopping  = "Shopping"
    case bills     = "Bills"
    case other     = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food:      return "fork.knife"
        case .transport: return "car.fill"
        case .shopping:  return "bag.fill"
        case .bills:     return "doc.text.fill"
        case .other:     return "ellipsis.circle.fill"
        }
    }

    var shortLabel: String {
        switch self {
        case .food:      return "FOOD"
        case .transport: return "TRANS"
        case .shopping:  return "SHOP"
        case .bills:     return "BILLS"
        case .other:     return "OTHER"
        }
    }

    var colorHex: String {
        switch self {
        case .food:      return "F97316"   
        case .transport: return "EF4444"  
        case .shopping:  return "8B5CF6"   
        case .bills:     return "3B82F6"   
        case .other:     return "6B7280"  
        }
    }
}
