import CoreData
import Foundation

@objc(CDReceipt)
public class CDReceipt: NSManagedObject {

    @NSManaged public var id:          UUID
    @NSManaged public var userId:      String?
    @NSManaged public var title:       String
    @NSManaged public var category:    String
    @NSManaged public var date:        Date
    @NSManaged public var amount:      Double
    @NSManaged public var notes:       String
    @NSManaged public var isFavorite:  Bool
    @NSManaged public var tagsJSON:    String  
    @NSManaged public var imageURL:    String?
    @NSManaged public var createdAt:   Date
    @NSManaged public var updatedAt:   Date
}

extension CDReceipt {

    func populate(from receipt: Receipt) {
        id         = receipt.id
        userId     = receipt.userId
        title      = receipt.title
        category   = receipt.category.rawValue
        date       = receipt.date
        amount     = receipt.amount
        notes      = receipt.notes
        isFavorite = receipt.isFavorite
        imageURL   = receipt.imageURL
        createdAt  = receipt.createdAt
        updatedAt  = receipt.updatedAt
        tagsJSON   = (try? JSONEncoder().encode(receipt.tags)).flatMap {
            String(data: $0, encoding: .utf8)
        } ?? "[]"
    }

    func toDomainModel() -> Receipt {
        let tags: [String] = tagsJSON.data(using: .utf8)
            .flatMap { try? JSONDecoder().decode([String].self, from: $0) } ?? []

        return Receipt(
            id:         id,
            userId:     userId,
            title:      title,
            category:   ReceiptCategory(rawValue: category) ?? .other,
            date:       date,
            amount:     amount,
            notes:      notes,
            isFavorite: isFavorite,
            tags:       tags,
            imageURL:   imageURL,
            createdAt:  createdAt,
            updatedAt:  updatedAt
        )
    }
}

extension CDReceipt {

    static func fetchRequest(for userId: String) -> NSFetchRequest<CDReceipt> {
        let req = NSFetchRequest<CDReceipt>(entityName: "CDReceipt")
        req.predicate = NSPredicate(format: "userId == %@", userId)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \CDReceipt.date, ascending: false)]
        return req
    }

    static func fetchRequest(id: UUID) -> NSFetchRequest<CDReceipt> {
        let req = NSFetchRequest<CDReceipt>(entityName: "CDReceipt")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return req
    }
}
