// MockReceiptService.swift
// ReceiptSnap — In-memory receipt service for unit tests and development.
// All mutations are reflected immediately in mockReceipts.

import Foundation
import UIKit

final class MockReceiptService: ReceiptServiceProtocol {

    var mockReceipts: [Receipt] = Receipt.mockReceipts()
    var shouldThrow: Bool       = false
    var delay: TimeInterval     = 0   // simulate network latency in tests

    private func maybeThrow() throws {
        if shouldThrow { throw ServiceError.networkError("Mock error") }
    }

    func fetchReceipts(userId: String) async throws -> [Receipt] {
        try maybeThrow()
        try await simulateDelay()
        return mockReceipts.filter { $0.userId == nil || $0.userId == userId }
            .sorted { $0.date > $1.date }
    }

    func fetchRecent(userId: String, limit: Int) async throws -> [Receipt] {
        try maybeThrow()
        return Array(try await fetchReceipts(userId: userId).prefix(limit))
    }

    func fetchReceipts(userId: String, month: Int, year: Int) async throws -> [Receipt] {
        try maybeThrow()
        let cal = Calendar.current
        return try await fetchReceipts(userId: userId).filter {
            let comps = cal.dateComponents([.month, .year], from: $0.date)
            return comps.month == month && comps.year == year
        }
    }

    func fetchReceipts(userId: String, from: Date, to: Date) async throws -> [Receipt] {
        try maybeThrow()
        return try await fetchReceipts(userId: userId)
            .filter { $0.date >= from && $0.date <= to }
    }

    func addReceipt(_ receipt: Receipt, image: UIImage?) async throws -> Receipt {
        try maybeThrow()
        try await simulateDelay()
        var saved = receipt
        // Simulate URL generation when image provided
        if image != nil { saved = Receipt(
            id:          saved.id,
            userId:      saved.userId,
            title:       saved.title,
            category:    saved.category,
            date:        saved.date,
            amount:      saved.amount,
            notes:       saved.notes,
            isFavorite:  saved.isFavorite,
            tags:        saved.tags,
            imageURL:    "https://mock-storage.example/\(saved.id).jpg",
            splitDetail: saved.splitDetail,
            createdAt:   saved.createdAt,
            updatedAt:   Date()
        )}
        mockReceipts.insert(saved, at: 0)
        return saved
    }

    func updateReceipt(_ receipt: Receipt, image: UIImage?) async throws -> Receipt {
        try maybeThrow()
        try await simulateDelay()
        var updated = receipt
        updated = Receipt(
            id:          updated.id,
            userId:      updated.userId,
            title:       updated.title,
            category:    updated.category,
            date:        updated.date,
            amount:      updated.amount,
            notes:       updated.notes,
            isFavorite:  updated.isFavorite,
            tags:        updated.tags,
            imageURL:    image != nil ? "https://mock-storage.example/\(updated.id).jpg" : updated.imageURL,
            splitDetail: updated.splitDetail,
            createdAt:   updated.createdAt,
            updatedAt:   Date()
        )
        if let i = mockReceipts.firstIndex(where: { $0.id == updated.id }) {
            mockReceipts[i] = updated
        }
        return updated
    }

    func deleteReceipt(id: UUID, userId: String) async throws {
        try maybeThrow()
        try await simulateDelay()
        mockReceipts.removeAll { $0.id == id }
    }

    private func simulateDelay() async throws {
        guard delay > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}
