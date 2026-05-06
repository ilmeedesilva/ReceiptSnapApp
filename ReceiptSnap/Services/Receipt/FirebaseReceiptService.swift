import Foundation
import UIKit
import FirebaseFirestore
import FirebaseStorage

final class FirebaseReceiptService: ReceiptServiceProtocol {

    private let db      = Firestore.firestore()
    private let storage = Storage.storage()

    private let collection = "receipts"


    func fetchReceipts(userId: String) async throws -> [Receipt] {
        do {
            let snap = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .getDocuments()
            return snap.documents.compactMap { decode($0) }
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }

    func fetchRecent(userId: String, limit: Int) async throws -> [Receipt] {
        do {
            let snap = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "date", descending: true)
                .limit(to: limit)
                .getDocuments()
            return snap.documents.compactMap { decode($0) }
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }

    func fetchReceipts(userId: String, month: Int, year: Int) async throws -> [Receipt] {
        let cal = Calendar.current
        var startComps = DateComponents(year: year, month: month, day: 1)
        let start = cal.date(from: startComps) ?? Date()
        startComps.month = (month % 12) + 1
        startComps.year  = month == 12 ? year + 1 : year
        let end = cal.date(from: startComps) ?? Date()
        return try await fetchReceipts(userId: userId, from: start, to: end)
    }

    func fetchReceipts(userId: String, from: Date, to: Date) async throws -> [Receipt] {
        do {
            let snap = try await db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: from))
                .whereField("date", isLessThan: Timestamp(date: to))
                .order(by: "date", descending: true)
                .getDocuments()
            return snap.documents.compactMap { decode($0) }
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }


    func addReceipt(_ receipt: Receipt, image: UIImage?) async throws -> Receipt {
        guard let userId = validatedUserId(from: receipt) else {
            throw ServiceError.invalidInput("Missing user ID for receipt upload.")
        }

        var saved = receipt
        if let img = image {
            let url = try await uploadImage(img, userId: userId, receiptId: receipt.id)
            saved = withImageURL(saved, url: url.absoluteString)
        }
        try await write(saved)
        return saved
    }

    func updateReceipt(_ receipt: Receipt, image: UIImage?) async throws -> Receipt {
        guard let userId = validatedUserId(from: receipt) else {
            throw ServiceError.invalidInput("Missing user ID for receipt upload.")
        }

        var updated = receipt
        updated = withUpdatedAt(updated)
        if let img = image {
            if let old = receipt.imageURL, let ref = try? storageRef(from: old) {
                try? await ref.delete()
            }
            let url = try await uploadImage(img, userId: userId, receiptId: receipt.id)
            updated = withImageURL(updated, url: url.absoluteString)
        }
        try await write(updated)
        return updated
    }

    func deleteReceipt(id: UUID, userId: String) async throws {
        if let receipt = try? await fetchOne(id: id, userId: userId),
           let imageURL = receipt.imageURL,
           let ref = try? storageRef(from: imageURL) {
            try? await ref.delete()
        }
        do {
            try await db.collection(collection).document(id.uuidString).delete()
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }


    private func write(_ receipt: Receipt) async throws {
        let data = encode(receipt)
        do {
            try await db.collection(collection)
                .document(receipt.id.uuidString)
                .setData(data, merge: true)
        } catch {
            throw ServiceError.networkError(error.localizedDescription)
        }
    }

    private func fetchOne(id: UUID, userId: String) async throws -> Receipt? {
        let doc = try? await db.collection(collection).document(id.uuidString).getDocument()
        return doc.flatMap { decode($0) }
    }

    private func uploadImage(_ image: UIImage, userId: String, receiptId: UUID) async throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ServiceError.invalidInput("Cannot convert image to JPEG.")
        }
        let ref = storage.reference().child("receipts/\(userId)/\(receiptId.uuidString).jpg")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: meta)
        let url = try await ref.downloadURL()
        return url
    }

    private func validatedUserId(from receipt: Receipt) -> String? {
        guard let raw = receipt.userId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }
        return raw
    }

    private func storageRef(from urlString: String) throws -> StorageReference {
        storage.reference(forURL: urlString)
    }


    private func encode(_ r: Receipt) -> [String: Any] {
        var data: [String: Any] = [
            "id":          r.id.uuidString,
            "userId":      r.userId ?? "",
            "title":       r.title,
            "category":    r.category.rawValue,
            "date":        Timestamp(date: r.date),
            "amount":      r.amount,
            "notes":       r.notes,
            "isFavorite":  r.isFavorite,
            "tags":        r.tags,
            "createdAt":   Timestamp(date: r.createdAt),
            "updatedAt":   Timestamp(date: r.updatedAt),
        ]
        if let url = r.imageURL { data["imageURL"] = url }
        if let split = r.splitDetail {
            data["split"] = [
                "splitId":       split.splitId.uuidString,
                "isEnabled":     split.isEnabled,
                "splitWithName": split.splitWithName,
                "splitType":     split.splitType.rawValue,
                "yourAmount":    split.yourAmount,
                "otherAmount":   split.otherAmount,
            ]
        }
        return data
    }

    private func decode(_ doc: DocumentSnapshot) -> Receipt? {
        guard let data = doc.data() else { return nil }
        guard
            let idStr    = data["id"]       as? String, let id = UUID(uuidString: idStr),
            let title    = data["title"]    as? String,
            let catRaw   = data["category"] as? String,
            let dateTS   = data["date"]     as? Timestamp,
            let amount   = data["amount"]   as? Double
        else { return nil }

        let userId    = data["userId"]    as? String
        let notes     = data["notes"]     as? String ?? ""
        let isFav     = data["isFavorite"] as? Bool ?? false
        let tags      = data["tags"]      as? [String] ?? []
        let imageURL  = data["imageURL"]  as? String
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? dateTS.dateValue()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? dateTS.dateValue()

        var split: SplitDetail?
        if let sd = data["split"] as? [String: Any],
           let enabled = sd["isEnabled"] as? Bool, enabled {
            split = SplitDetail(
                splitId:       UUID(uuidString: sd["splitId"] as? String ?? "") ?? UUID(),
                receiptId:     id,
                isEnabled:     true,
                splitWithName: sd["splitWithName"] as? String ?? "",
                splitType:     SplitType(rawValue: sd["splitType"] as? String ?? "") ?? .equal,
                yourAmount:    sd["yourAmount"]  as? Double ?? 0,
                otherAmount:   sd["otherAmount"] as? Double ?? 0
            )
        }

        return Receipt(
            id:          id,
            userId:      userId,
            title:       title,
            category:    ReceiptCategory(rawValue: catRaw) ?? .other,
            date:        dateTS.dateValue(),
            amount:      amount,
            notes:       notes,
            isFavorite:  isFav,
            tags:        tags,
            imageURL:    imageURL,
            splitDetail: split,
            createdAt:   createdAt,
            updatedAt:   updatedAt
        )
    }


    private func withImageURL(_ r: Receipt, url: String) -> Receipt {
        Receipt(id: r.id, userId: r.userId, title: r.title, category: r.category,
                date: r.date, amount: r.amount, notes: r.notes, isFavorite: r.isFavorite,
                tags: r.tags, imageURL: url, splitDetail: r.splitDetail,
                createdAt: r.createdAt, updatedAt: r.updatedAt)
    }

    private func withUpdatedAt(_ r: Receipt) -> Receipt {
        Receipt(id: r.id, userId: r.userId, title: r.title, category: r.category,
                date: r.date, amount: r.amount, notes: r.notes, isFavorite: r.isFavorite,
                tags: r.tags, imageURL: r.imageURL, splitDetail: r.splitDetail,
                createdAt: r.createdAt, updatedAt: Date())
    }
}