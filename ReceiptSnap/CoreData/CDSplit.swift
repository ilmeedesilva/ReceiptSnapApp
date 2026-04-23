import CoreData
import Foundation

@objc(CDSplit)
public class CDSplit: NSManagedObject {

    @NSManaged public var splitId:       UUID
    @NSManaged public var receiptId:     UUID?
    @NSManaged public var isEnabled:     Bool
    @NSManaged public var splitWithName: String
    @NSManaged public var splitTypeRaw:  String
    @NSManaged public var yourAmount:    Double
    @NSManaged public var otherAmount:   Double
}


extension CDSplit {

    func populate(from split: SplitDetail) {
        splitId       = split.splitId
        receiptId     = split.receiptId
        isEnabled     = split.isEnabled
        splitWithName = split.splitWithName
        splitTypeRaw  = split.splitType.rawValue
        yourAmount    = split.yourAmount
        otherAmount   = split.otherAmount
    }

    func toDomainModel() -> SplitDetail {
        SplitDetail(
            splitId:       splitId,
            receiptId:     receiptId,
            isEnabled:     isEnabled,
            splitWithName: splitWithName,
            splitType:     SplitType(rawValue: splitTypeRaw) ?? .equal,
            yourAmount:    yourAmount,
            otherAmount:   otherAmount
        )
    }
}


extension CDSplit {

    static func fetchRequest(receiptId: UUID) -> NSFetchRequest<CDSplit> {
        let req = NSFetchRequest<CDSplit>(entityName: "CDSplit")
        req.predicate = NSPredicate(format: "receiptId == %@", receiptId as CVarArg)
        req.fetchLimit = 1
        return req
    }
}
