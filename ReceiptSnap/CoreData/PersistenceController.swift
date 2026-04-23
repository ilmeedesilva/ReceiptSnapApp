import CoreData
import Foundation

final class PersistenceController {

    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        controller.seedPreviewData()
        return controller
    }()


    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ReceiptSnap",
                                          managedObjectModel: Self.model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData failed to load: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            ctx.rollback()
            print("[CoreData] Save failed: \(error)")
        }
    }

    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(ctx)
            guard ctx.hasChanges else { return }
            try? ctx.save()
        }
    }

    private func seedPreviewData() {
        let ctx = container.viewContext
        Receipt.mockReceipts().forEach { r in
            let entity = CDReceipt(context: ctx)
            entity.populate(from: r)
        }
        let b = Budget.mock()
        let budgetEntity = CDBudget(context: ctx)
        budgetEntity.populate(from: b)
        try? ctx.save()
    }
}


extension PersistenceController {

    static let model: NSManagedObjectModel = {
        let model = NSManagedObjectModel()

        let receiptEntity = NSEntityDescription()
        receiptEntity.name = "CDReceipt"
        receiptEntity.managedObjectClassName = "ReceiptSnap.CDReceipt"

        let receiptAttrs: [(String, NSAttributeType, Bool)] = [
            ("id",            .UUIDAttributeType,    false),
            ("userId",        .stringAttributeType,  true),
            ("title",         .stringAttributeType,  false),
            ("category",      .stringAttributeType,  false),
            ("date",          .dateAttributeType,    false),
            ("amount",        .doubleAttributeType,  false),
            ("notes",         .stringAttributeType,  false),
            ("isFavorite",    .booleanAttributeType, false),
            ("tagsJSON",      .stringAttributeType,  false),  
            ("imageURL",      .stringAttributeType,  true),
            ("createdAt",     .dateAttributeType,    false),
            ("updatedAt",     .dateAttributeType,    false),
        ]
        receiptEntity.properties = receiptAttrs.map { makeAttr($0.0, $0.1, optional: $0.2) }


        let budgetEntity = NSEntityDescription()
        budgetEntity.name = "CDBudget"
        budgetEntity.managedObjectClassName = "ReceiptSnap.CDBudget"

        let budgetAttrs: [(String, NSAttributeType, Bool)] = [
            ("id",              .UUIDAttributeType,    false),
            ("userId",          .stringAttributeType,  true),
            ("monthlyLimit",    .doubleAttributeType,  false),
            ("currentSpending", .doubleAttributeType,  false),
            ("period",          .stringAttributeType,  false),
            ("month",           .integer16AttributeType, false),
            ("year",            .integer16AttributeType, false),
            ("alertEnabled",    .booleanAttributeType, false),
            ("alertThreshold",  .doubleAttributeType,  false),
            ("createdAt",       .dateAttributeType,    false),
        ]
        budgetEntity.properties = budgetAttrs.map { makeAttr($0.0, $0.1, optional: $0.2) }


        let notifEntity = NSEntityDescription()
        notifEntity.name = "CDNotification"
        notifEntity.managedObjectClassName = "ReceiptSnap.CDNotification"

        let notifAttrs: [(String, NSAttributeType, Bool)] = [
            ("id",              .UUIDAttributeType,   false),
            ("userId",          .stringAttributeType, true),
            ("typeRaw",         .stringAttributeType, false),
            ("title",           .stringAttributeType, false),
            ("message",         .stringAttributeType, false),
            ("timestamp",       .dateAttributeType,   false),
            ("isRead",          .booleanAttributeType, false),
            ("relatedEntityId", .stringAttributeType, true),
            ("relatedScreen",   .stringAttributeType, true),
        ]
        notifEntity.properties = notifAttrs.map { makeAttr($0.0, $0.1, optional: $0.2) }


        let splitEntity = NSEntityDescription()
        splitEntity.name = "CDSplit"
        splitEntity.managedObjectClassName = "ReceiptSnap.CDSplit"

        let splitAttrs: [(String, NSAttributeType, Bool)] = [
            ("splitId",       .UUIDAttributeType,   false),
            ("receiptId",     .UUIDAttributeType,   true),
            ("isEnabled",     .booleanAttributeType, false),
            ("splitWithName", .stringAttributeType, false),
            ("splitTypeRaw",  .stringAttributeType, false),
            ("yourAmount",    .doubleAttributeType,  false),
            ("otherAmount",   .doubleAttributeType,  false),
        ]
        splitEntity.properties = splitAttrs.map { makeAttr($0.0, $0.1, optional: $0.2) }

        model.entities = [receiptEntity, budgetEntity, notifEntity, splitEntity]
        return model
    }()

    private static func makeAttr(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        return attr
    }
}
