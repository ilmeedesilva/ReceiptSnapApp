import CoreData
import Foundation

@objc(CDNotification)
public class CDNotification: NSManagedObject {

    @NSManaged public var id:              UUID
    @NSManaged public var userId:          String?
    @NSManaged public var typeRaw:         String
    @NSManaged public var title:           String
    @NSManaged public var message:         String
    @NSManaged public var timestamp:       Date
    @NSManaged public var isRead:          Bool
    @NSManaged public var relatedEntityId: String?
    @NSManaged public var relatedScreen:   String?
}


extension CDNotification {

    func populate(from notification: AppNotification) {
        id              = notification.id
        userId          = notification.userId
        typeRaw         = notification.type.rawValue
        title           = notification.title
        message         = notification.message
        timestamp       = notification.timestamp
        isRead          = notification.isRead
        relatedEntityId = notification.relatedEntityId
        relatedScreen   = notification.relatedScreen
    }

    func toDomainModel() -> AppNotification {
        AppNotification(
            id:              id,
            userId:          userId,
            type:            NotificationType(rawValue: typeRaw) ?? .dailyReminder,
            title:           title,
            message:         message,
            timestamp:       timestamp,
            isRead:          isRead,
            relatedEntityId: relatedEntityId,
            relatedScreen:   relatedScreen
        )
    }
}

extension CDNotification {

    static func fetchRequest(for userId: String) -> NSFetchRequest<CDNotification> {
        let req = NSFetchRequest<CDNotification>(entityName: "CDNotification")
        req.predicate = NSPredicate(format: "userId == %@", userId)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \CDNotification.timestamp, ascending: false)]
        return req
    }

    static func unreadRequest(for userId: String) -> NSFetchRequest<CDNotification> {
        let req = NSFetchRequest<CDNotification>(entityName: "CDNotification")
        req.predicate = NSPredicate(format: "userId == %@ AND isRead == NO", userId)
        return req
    }
}
