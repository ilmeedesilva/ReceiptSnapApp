
import SwiftUI
import CoreData
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {

    // MARK: - Published state

    @Published var notifications: [AppNotification] = []
    @Published var isLoading:     Bool               = false
    @Published var errorMessage:  String?            = nil

    // MARK: - Dependencies

    private let notificationService: NotificationServiceProtocol
    private let persistence:         PersistenceController

    // MARK: - Init

    init(
        notificationService: NotificationServiceProtocol = ServiceLocator.shared.notificationService,
        persistence:         PersistenceController       = ServiceLocator.shared.persistence
    ) {
        self.notificationService = notificationService
        self.persistence         = persistence
    }

    // MARK: - Computed (pure — unit-testable)

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }
    var hasUnread:   Bool { unreadCount > 0 }

    var groupedNotifications: [(group: NotificationGroup, items: [AppNotification])] {
        let order: [NotificationGroup] = [.today, .yesterday, .thisWeek, .older]
        let now = Date()
        return order.compactMap { group in
            let items = notifications.filter { $0.group(from: now) == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    // MARK: - Load

    func loadNotifications(userId: String? = nil) async {
        isLoading = true
        defer { isLoading = false }

        // Load from CoreData first (offline-capable)
        let cached = loadFromCoreData(userId: userId)
        if !cached.isEmpty {
            notifications = cached
        } else {
            notifications = AppNotification.mockNotifications()
        }
    }

    // MARK: - Mutations

    func markAsRead(id: UUID) {
        guard let i = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[i].isRead = true
        updateCoreData(id: id, isRead: true)
        notificationService.markRead(id: id)
    }

    func markAllAsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
        let ids = notifications.map { $0.id }
        persistence.performBackgroundTask { ctx in
            ids.forEach { id in
                let req = NSFetchRequest<CDNotification>(entityName: "CDNotification")
                req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                (try? ctx.fetch(req).first)?.isRead = true
            }
        }
    }

    func delete(id: UUID) {
        notifications.removeAll { $0.id == id }
        persistence.performBackgroundTask { ctx in
            let req = NSFetchRequest<CDNotification>(entityName: "CDNotification")
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            (try? ctx.fetch(req))?.forEach { ctx.delete($0) }
        }
    }

    func clearAll() {
        let userId = notifications.first?.userId
        notifications.removeAll()
        persistence.performBackgroundTask { ctx in
            let req = CDNotification.fetchRequest(for: userId ?? "")
            (try? ctx.fetch(req))?.forEach { ctx.delete($0) }
        }
    }

    /// Called by NotificationService when a new notification fires.
    func receive(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        persistence.performBackgroundTask { ctx in
            let entity = CDNotification(context: ctx)
            entity.populate(from: notification)
        }
    }

    // MARK: - CoreData

    private func loadFromCoreData(userId: String?) -> [AppNotification] {
        let ctx = persistence.viewContext
        let req = CDNotification.fetchRequest(for: userId ?? "")
        if userId == nil { req.predicate = nil }
        return (try? ctx.fetch(req))?.map { $0.toDomainModel() } ?? []
    }

    private func updateCoreData(id: UUID, isRead: Bool) {
        persistence.performBackgroundTask { ctx in
            let req = NSFetchRequest<CDNotification>(entityName: "CDNotification")
            req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            (try? ctx.fetch(req).first)?.isRead = isRead
        }
    }
}
