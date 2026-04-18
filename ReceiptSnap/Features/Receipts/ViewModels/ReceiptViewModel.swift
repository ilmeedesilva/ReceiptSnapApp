import SwiftUI
import CoreData
import UIKit
import Combine

extension Notification.Name {
   
    static let receiptsChanged    = Notification.Name("rs.receiptsChanged")
    static let receiptAdded       = Notification.Name("rs.receiptAdded")
    static let switchToReceipts   = Notification.Name("rs.switchToReceipts")
    static let switchToDashboard  = Notification.Name("rs.switchToDashboard")
    static let showWeeklyReport   = Notification.Name("rs.showWeeklyReport")
    static let showBudgetFeedback = Notification.Name("rs.showBudgetFeedback")
    static let showBudgetAlert    = Notification.Name("rs.showBudgetAlert")
}

@MainActor
final class ReceiptViewModel: ObservableObject {

    @Published var receipts:     [Receipt]     = []
    @Published var filter:       ReceiptFilter  = ReceiptFilter()
    @Published var isLoading:    Bool           = false
    @Published var isSyncing:    Bool           = false
    @Published var errorMessage: String?        = nil


    private let receiptService: ReceiptServiceProtocol
    private let searchService:  SearchService
    private let splitService:   SplitService
    private let persistence:    PersistenceController


    init(
        receiptService: ReceiptServiceProtocol = ServiceLocator.shared.receiptService,
        searchService:  SearchService          = ServiceLocator.shared.searchService,
        splitService:   SplitService           = ServiceLocator.shared.splitService,
        persistence:    PersistenceController  = ServiceLocator.shared.persistence
    ) {
        self.receiptService = receiptService
        self.searchService  = searchService
        self.splitService   = splitService
        self.persistence    = persistence
    }


    var filteredReceipts: [Receipt] {
        searchService.filter(receipts, by: filter)
    }

    var groupedReceipts: [(label: String, items: [Receipt])] {
        searchService.group(filteredReceipts)
    }

    var searchText: String {
        get { filter.searchText }
        set { filter.searchText = newValue }
    }
    var selectedCategory: ReceiptCategory? {
        get { filter.categories.count == 1 ? filter.categories.first : nil }
        set {
            if let cat = newValue { filter.categories = [cat] }
            else                  { filter.categories = [] }
        }
    }


    func loadReceipts(userId: String? = nil) async {
        if receipts.isEmpty {
            loadFromCoreData(userId: userId)
        }

        guard let uid = userId, !uid.isEmpty else { return }
        isSyncing = true
        defer { isSyncing = false }
        do {
            let remote = try await receiptService.fetchReceipts(userId: uid)
            let remoteIds = Set(remote.map(\.id))
            let localOnly = receipts.filter { !remoteIds.contains($0.id) }
            receipts = (localOnly + remote).sorted { $0.date > $1.date }
            saveToCoreData(remote, userId: uid)
        } catch {
            errorMessage = "Sync failed — showing cached data."
        }
    }


    enum ValidationError: LocalizedError {
        case missingTitle, zeroAmount, invalidSplit(String)
        var errorDescription: String? {
            switch self {
            case .missingTitle:        return "Please enter a merchant name."
            case .zeroAmount:          return "Amount must be greater than zero."
            case .invalidSplit(let m): return m
            }
        }
    }

    func validate(_ receipt: Receipt) throws {
        guard !receipt.title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ValidationError.missingTitle
        }
        guard receipt.amount != 0 else {
            throw ValidationError.zeroAmount
        }
        if let split = receipt.splitDetail, split.isEnabled {
            let v = splitService.validateCustomSplit(
                yourAmount:  split.yourAmount,
                otherAmount: split.otherAmount,
                total:       receipt.amount
            )
            if !v.isValid {
                throw ValidationError.invalidSplit(v.errorMessage ?? "Invalid split.")
            }
        }
    }


    func addReceipt(_ receipt: Receipt, image: UIImage? = nil) async {
        errorMessage = nil
        do { try validate(receipt) } catch {
            errorMessage = error.localizedDescription; return
        }

        isLoading = true
        defer { isLoading = false }

        receipts.insert(receipt, at: 0)
        saveOneToCoreData(receipt)

        do {
            let saved = try await receiptService.addReceipt(receipt, image: image)
            if let i = receipts.firstIndex(where: { $0.id == saved.id }) {
                receipts[i] = saved
                saveOneToCoreData(saved)
            }
            NotificationCenter.default.post(name: .receiptAdded,    object: nil)
            NotificationCenter.default.post(name: .receiptsChanged, object: nil)
        } catch {
            receipts.removeAll { $0.id == receipt.id }
            deleteFromCoreData(id: receipt.id)
            errorMessage = "Could not save receipt. Please try again."
        }
    }

    func updateReceipt(_ updated: Receipt, image: UIImage? = nil) async {
        errorMessage = nil
        do { try validate(updated) } catch {
            errorMessage = error.localizedDescription; return
        }

        isLoading = true
        defer { isLoading = false }

        if let i = receipts.firstIndex(where: { $0.id == updated.id }) {
            receipts[i] = updated
            saveOneToCoreData(updated)
        }

        do {
            let saved = try await receiptService.updateReceipt(updated, image: image)
            if let i = receipts.firstIndex(where: { $0.id == saved.id }) {
                receipts[i] = saved
                saveOneToCoreData(saved)
            }
        } catch {
            loadFromCoreData(userId: updated.userId)
            errorMessage = "Could not update receipt. Please try again."
        }
        NotificationCenter.default.post(name: .receiptsChanged, object: nil)
    }

    func deleteReceipt(id: UUID) async {
        guard let receipt = receipts.first(where: { $0.id == id }) else { return }
        isLoading = true
        defer { isLoading = false }

        receipts.removeAll { $0.id == id }
        deleteFromCoreData(id: id)

        do {
            try await receiptService.deleteReceipt(id: id, userId: receipt.userId ?? "")
        } catch {
            receipts.insert(receipt, at: 0)
            saveOneToCoreData(receipt)
            errorMessage = "Could not delete receipt. Please try again."
        }
        NotificationCenter.default.post(name: .receiptsChanged, object: nil)
    }

    func toggleFavorite(id: UUID) {
        guard let i = receipts.firstIndex(where: { $0.id == id }) else { return }
        receipts[i].isFavorite.toggle()
        let updated = receipts[i]
        saveOneToCoreData(updated)
        Task { try? await receiptService.updateReceipt(updated, image: nil) }
    }


    func receipt(for id: UUID) -> Receipt? {
        receipts.first { $0.id == id }
    }

    func totalSpending(month: Int, year: Int) -> Double {
        let cal = Calendar.current
        return receipts
            .filter {
                let c = cal.dateComponents([.month, .year], from: $0.date)
                return c.month == month && c.year == year
            }
            .reduce(0) { $0 + abs($1.amount) }
    }


    private func loadFromCoreData(userId: String?) {
        let ctx = persistence.viewContext
        let req = CDReceipt.fetchRequest(for: userId ?? "")
        if userId == nil { req.predicate = nil }
        let cached = (try? ctx.fetch(req))?.map { $0.toDomainModel() } ?? []
        if !cached.isEmpty {
            receipts = cached
        } else if receipts.isEmpty {
            receipts = Receipt.mockReceipts()
        }
    }

    private func saveOneToCoreData(_ receipt: Receipt) {
        persistence.performBackgroundTask { ctx in
            let req    = CDReceipt.fetchRequest(id: receipt.id)
            let entity = (try? ctx.fetch(req).first) ?? CDReceipt(context: ctx)
            entity.populate(from: receipt)
        }
    }

    private func saveToCoreData(_ items: [Receipt], userId: String) {
        persistence.performBackgroundTask { ctx in
            let old = (try? ctx.fetch(CDReceipt.fetchRequest(for: userId))) ?? []
            old.forEach { ctx.delete($0) }
            items.forEach { r in
                let e = CDReceipt(context: ctx)
                e.populate(from: r)
            }
        }
    }

    private func deleteFromCoreData(id: UUID) {
        persistence.performBackgroundTask { ctx in
            let req = CDReceipt.fetchRequest(id: id)
            (try? ctx.fetch(req))?.forEach { ctx.delete($0) }
        }
    }
}
