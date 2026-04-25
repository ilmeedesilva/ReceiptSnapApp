import Foundation

enum ReceiptRoute: Hashable {
    case detail(receiptID: UUID)
    case edit(receiptID: UUID)
    case deleteSuccess
}
