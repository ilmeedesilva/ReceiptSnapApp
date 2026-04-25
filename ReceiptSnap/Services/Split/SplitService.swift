
import Foundation


struct SplitValidation {
    let isValid: Bool
    let errorMessage: String?
}


final class SplitService {

    // MARK: - Equal split

    /// Divide `total` equally among `participants` (minimum 2).
    /// Returns the per-person share.
    func equalShare(total: Double, participants: Int) -> Double {
        guard participants >= 2 else { return abs(total) }
        return abs(total) / Double(participants)
    }

    /// Build a SplitDetail for a 2-person equal split.
    func buildEqualSplit(total: Double, partnerName: String,
                          receiptId: UUID? = nil) -> SplitDetail {
        let share = equalShare(total: total, participants: 2)
        return SplitDetail(
            receiptId:     receiptId,
            isEnabled:     true,
            splitWithName: partnerName,
            splitType:     .equal,
            yourAmount:    share,
            otherAmount:   share
        )
    }

    // MARK: - Custom split

    /// Validate a custom split where the two amounts must sum to `total`.
    func validateCustomSplit(yourAmount: Double, otherAmount: Double,
                              total: Double) -> SplitValidation {
        guard yourAmount >= 0, otherAmount >= 0 else {
            return SplitValidation(isValid: false, errorMessage: "Amounts cannot be negative.")
        }
        guard yourAmount + otherAmount > 0 else {
            return SplitValidation(isValid: false, errorMessage: "Split amounts cannot both be zero.")
        }
        let diff = abs((yourAmount + otherAmount) - abs(total))
        if diff > 0.01 {
            return SplitValidation(
                isValid: false,
                errorMessage: String(format: "Amounts must add up to $%.2f.", abs(total))
            )
        }
        return SplitValidation(isValid: true, errorMessage: nil)
    }

    /// Build a SplitDetail for a custom split after validation passes.
    func buildCustomSplit(yourAmount: Double, otherAmount: Double,
                           partnerName: String, receiptId: UUID? = nil) -> SplitDetail {
        SplitDetail(
            receiptId:     receiptId,
            isEnabled:     true,
            splitWithName: partnerName,
            splitType:     .custom,
            yourAmount:    yourAmount,
            otherAmount:   otherAmount
        )
    }

    // MARK: - Summary helpers

    /// Total amount paid by the partner across all split receipts.
    func totalPaidByOthers(in receipts: [Receipt]) -> Double {
        receipts
            .compactMap { $0.splitDetail }
            .filter { $0.isEnabled }
            .reduce(0) { $0 + $1.otherAmount }
    }

    /// User's own share total across all split receipts.
    func totalUserShare(in receipts: [Receipt]) -> Double {
        receipts
            .compactMap { $0.splitDetail }
            .filter { $0.isEnabled }
            .reduce(0) { $0 + $1.yourAmount }
    }
}
