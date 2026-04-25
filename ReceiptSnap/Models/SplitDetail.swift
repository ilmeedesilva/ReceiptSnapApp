import Foundation

enum SplitType: String, Codable, CaseIterable, Identifiable {
    case equal  = "Equal Split"
    case custom = "Custom Split"
    var id: String { rawValue }
}


struct SplitDetail: Codable, Equatable {

    var splitId: UUID          = UUID()    
    var receiptId: UUID?                  
    var isEnabled:      Bool      = false
    var splitWithName:  String    = ""
    var splitType:      SplitType = .equal
    var yourAmount:     Double    = 0
    var otherAmount:    Double    = 0


    var totalSplit: Double { yourAmount + otherAmount }


    func isValidCustomSplit(total: Double) -> Bool {
        abs(totalSplit - abs(total)) < 0.01
    }

    var difference: Double { totalSplit - yourAmount - otherAmount }


    static func equal(total: Double, receiptId: UUID? = nil) -> SplitDetail {
        let half = abs(total) / 2
        return SplitDetail(splitId: UUID(), receiptId: receiptId, isEnabled: true,
                           splitWithName: "", splitType: .equal,
                           yourAmount: half, otherAmount: half)
    }


    static func mockSplit(total: Double = 60) -> SplitDetail {
        equal(total: total)
    }

    static var mockContacts: [String] {
        ["Alex Rivera", "Jamie Chen", "Morgan Lee", "Sam Taylor", "Riley Kim"]
    }
}
