
import Foundation
import UIKit


protocol ReceiptServiceProtocol: AnyObject {

    /// Full list of receipts for the current user, newest first.
    func fetchReceipts(userId: String) async throws -> [Receipt]

    /// The most recent `limit` receipts (dashboard preview).
    func fetchRecent(userId: String, limit: Int) async throws -> [Receipt]

    /// Receipts for a specific month/year.
    func fetchReceipts(userId: String, month: Int, year: Int) async throws -> [Receipt]

    /// Receipts within an inclusive date range.
    func fetchReceipts(userId: String, from: Date, to: Date) async throws -> [Receipt]

    /// Save a new receipt. If `image` is provided, upload to Storage first and attach the URL.
    func addReceipt(_ receipt: Receipt, image: UIImage?) async throws -> Receipt

    /// Overwrite an existing receipt. Optionally replace the image.
    func updateReceipt(_ receipt: Receipt, image: UIImage?) async throws -> Receipt

    /// Hard-delete a receipt by ID, removing the image from Storage as well.
    func deleteReceipt(id: UUID, userId: String) async throws
}
