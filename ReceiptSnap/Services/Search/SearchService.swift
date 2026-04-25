// SearchService.swift
// ReceiptSnap — Pure-function search and filter logic.
// All methods are synchronous and side-effect free — fully unit-testable.

import Foundation

// MARK: - Filter parameters

struct ReceiptFilter: Equatable {
    var searchText:      String                = ""
    var categories:      Set<ReceiptCategory>  = []   // empty = all categories
    var startDate:       Date?                 = nil
    var endDate:         Date?                 = nil
    var favoritesOnly:   Bool                  = false
    var minimumAmount:   Double                = 0
    var tags:            [String]              = []

    var isActive: Bool {
        !searchText.isEmpty || !categories.isEmpty || startDate != nil ||
        endDate != nil || favoritesOnly || minimumAmount > 0 || !tags.isEmpty
    }
}

// MARK: - Service

final class SearchService {

    // MARK: - Filter

    /// Apply all active filters to `receipts` and return the matching subset.
    /// This is a pure function — safe to call from a computed property.
    func filter(_ receipts: [Receipt], by params: ReceiptFilter) -> [Receipt] {
        receipts.filter { r in
            matchesSearch(r, query: params.searchText) &&
            matchesCategories(r, categories: params.categories) &&
            matchesDateRange(r, start: params.startDate, end: params.endDate) &&
            matchesFavorite(r, favoritesOnly: params.favoritesOnly) &&
            matchesMinAmount(r, minimum: params.minimumAmount) &&
            matchesTags(r, required: params.tags)
        }
    }

    // MARK: - Predicates (pure — individually unit-testable)

    func matchesSearch(_ receipt: Receipt, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return receipt.title.lowercased().contains(q) ||
               receipt.category.rawValue.lowercased().contains(q) ||
               receipt.notes.lowercased().contains(q) ||
               receipt.tags.contains { $0.lowercased().contains(q) }
    }

    func matchesCategories(_ receipt: Receipt, categories: Set<ReceiptCategory>) -> Bool {
        guard !categories.isEmpty else { return true }
        return categories.contains(receipt.category)
    }

    func matchesDateRange(_ receipt: Receipt, start: Date?, end: Date?) -> Bool {
        if let s = start, receipt.date < s { return false }
        if let e = end,   receipt.date > e { return false }
        return true
    }

    func matchesFavorite(_ receipt: Receipt, favoritesOnly: Bool) -> Bool {
        favoritesOnly ? receipt.isFavorite : true
    }

    func matchesMinAmount(_ receipt: Receipt, minimum: Double) -> Bool {
        minimum <= 0 ? true : abs(receipt.amount) >= minimum
    }

    func matchesTags(_ receipt: Receipt, required: [String]) -> Bool {
        guard !required.isEmpty else { return true }
        return required.allSatisfy { tag in receipt.tags.contains(tag) }
    }

    // MARK: - Grouping

    /// Group receipts into time-labelled sections: RECENT / LAST WEEK / OLDER.
    func group(_ receipts: [Receipt]) -> [(label: String, items: [Receipt])] {
        let cal   = Calendar.current
        let now   = Date()
        let thisWeekStart = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear],
                                                               from: now)) ?? now
        let lastWeekStart = cal.date(byAdding: .weekOfYear, value: -1, to: thisWeekStart) ?? now

        let recent   = receipts.filter { $0.date >= thisWeekStart }
        let lastWeek = receipts.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }
        let older    = receipts.filter { $0.date < lastWeekStart }

        var groups: [(String, [Receipt])] = []
        if !recent.isEmpty   { groups.append(("RECENT",    recent)) }
        if !lastWeek.isEmpty { groups.append(("LAST WEEK", lastWeek)) }
        if !older.isEmpty    { groups.append(("OLDER",     older)) }
        return groups
    }

    // MARK: - Sort

    enum SortOrder {
        case dateDescending, dateAscending, amountDescending, amountAscending
    }

    func sort(_ receipts: [Receipt], by order: SortOrder) -> [Receipt] {
        switch order {
        case .dateDescending:   return receipts.sorted { $0.date > $1.date }
        case .dateAscending:    return receipts.sorted { $0.date < $1.date }
        case .amountDescending: return receipts.sorted { abs($0.amount) > abs($1.amount) }
        case .amountAscending:  return receipts.sorted { abs($0.amount) < abs($1.amount) }
        }
    }
}
