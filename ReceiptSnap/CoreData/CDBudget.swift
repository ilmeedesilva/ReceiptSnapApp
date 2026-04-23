import CoreData
import Foundation

@objc(CDBudget)
public class CDBudget: NSManagedObject {

    @NSManaged public var id:              UUID
    @NSManaged public var userId:          String?
    @NSManaged public var monthlyLimit:    Double
    @NSManaged public var currentSpending: Double
    @NSManaged public var period:          String
    @NSManaged public var month:           Int16
    @NSManaged public var year:            Int16
    @NSManaged public var alertEnabled:    Bool
    @NSManaged public var alertThreshold:  Double
    @NSManaged public var createdAt:       Date
}

extension CDBudget {

    func populate(from budget: Budget) {
        id              = budget.id
        userId          = budget.userId
        monthlyLimit    = budget.monthlyLimit
        currentSpending = budget.currentSpending
        period          = budget.period
        month           = Int16(budget.month)
        year            = Int16(budget.year)
        alertEnabled    = budget.alertEnabled
        alertThreshold  = budget.alertThreshold
        createdAt       = budget.createdAt
    }

    func toDomainModel() -> Budget {
        Budget(
            id:              id,
            userId:          userId,
            monthlyLimit:    monthlyLimit,
            currentSpending: currentSpending,
            period:          period,
            alertEnabled:    alertEnabled,
            alertThreshold:  alertThreshold,
            createdAt:       createdAt
        )
    }
}


extension CDBudget {

    static func fetchRequest(for userId: String) -> NSFetchRequest<CDBudget> {
        let req = NSFetchRequest<CDBudget>(entityName: "CDBudget")
        req.predicate = NSPredicate(format: "userId == %@", userId)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \CDBudget.createdAt, ascending: false)]
        return req
    }

    static func fetchRequest(userId: String, month: Int, year: Int) -> NSFetchRequest<CDBudget> {
        let req = NSFetchRequest<CDBudget>(entityName: "CDBudget")
        req.predicate = NSPredicate(format: "userId == %@ AND month == %d AND year == %d",
                                    userId, month, year)
        req.fetchLimit = 1
        return req
    }
}
