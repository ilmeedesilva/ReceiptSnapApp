import Foundation
import FirebaseFirestore

final class FirebaseBudgetService: BudgetServiceProtocol {

    private let db         = Firestore.firestore()
    private let collection = "budgets"


    func fetchBudget(userId: String, month: Int, year: Int) async throws -> Budget? {
        do {
            let snap = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .whereField("month",  isEqualTo: month)
                .whereField("year",   isEqualTo: year)
                .limit(to: 1)
                .getDocuments()
            return snap.documents.first.flatMap { decode($0) }
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }

    func fetchBudgets(userId: String) async throws -> [Budget] {
        do {
            let snap = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments()
            return snap.documents
                .compactMap { decode($0) }
                .sorted { lhs, rhs in
                    if lhs.year == rhs.year { return lhs.month > rhs.month }
                    return lhs.year > rhs.year
                }
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }


    func createBudget(userId: String, monthlyLimit: Double, period: String,
                      alertEnabled: Bool, alertThreshold: Double) async throws -> Budget {
        let budget = Budget(userId: userId, monthlyLimit: monthlyLimit, currentSpending: 0,
                            period: period, alertEnabled: alertEnabled,
                            alertThreshold: alertThreshold)
        if try await fetchBudget(userId: userId, month: budget.month, year: budget.year) != nil {
            throw ServiceError.invalidInput("A budget already exists for \(budget.period).")
        }
        try await write(budget)
        return budget
    }

    func updateBudget(_ budget: Budget) async throws -> Budget {
        try await write(budget)
        return budget
    }

    func deleteBudget(id: UUID, userId: String) async throws {
        do {
            try await db.collection(collection).document(id.uuidString).delete()
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }


    private func write(_ budget: Budget) async throws {
        let data: [String: Any] = [
            "id":             budget.id.uuidString,
            "userId":         budget.userId ?? "",
            "monthlyLimit":   budget.monthlyLimit,
            "currentSpending": budget.currentSpending,
            "period":         budget.period,
            "month":          budget.month,
            "year":           budget.year,
            "alertEnabled":   budget.alertEnabled,
            "alertThreshold": budget.alertThreshold,
            "createdAt":      Timestamp(date: budget.createdAt),
        ]
        do {
            try await db.collection(collection)
                .document(budget.id.uuidString)
                .setData(data, merge: true)
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }

    private func decode(_ doc: DocumentSnapshot) -> Budget? {
        guard let data = doc.data(),
              let idStr = data["id"] as? String, let id = UUID(uuidString: idStr),
              let limit  = data["monthlyLimit"] as? Double,
              let period = data["period"] as? String
        else { return nil }

        let spending  = data["currentSpending"] as? Double ?? 0
        let userId    = data["userId"]          as? String
        let alertOn   = data["alertEnabled"]    as? Bool ?? true
        let threshold = data["alertThreshold"]  as? Double ?? 0.8
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Budget(id: id, userId: userId, monthlyLimit: limit,
                      currentSpending: spending, period: period,
                      alertEnabled: alertOn, alertThreshold: threshold,
                      createdAt: createdAt)
    }
}