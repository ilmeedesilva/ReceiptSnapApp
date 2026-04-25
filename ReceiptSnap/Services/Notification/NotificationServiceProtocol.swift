// NotificationServiceProtocol.swift
// ReceiptSnap — Contract for scheduling and managing local push notifications.

import Foundation
import CoreData
import UserNotifications

// MARK: - Protocol

protocol NotificationServiceProtocol: AnyObject {
    /// Request push notification permission from the user.
    func requestPermission() async -> Bool

    /// Schedule a repeating daily reminder at the specified time.
    func scheduleDailyReminder(at time: Date, message: String) async throws

    /// Cancel the daily reminder.
    func cancelDailyReminder() async

    /// Schedule a one-shot budget alert notification.
    func scheduleBudgetAlert(budget: Budget) async throws

    /// Remove all pending notifications.
    func cancelAll() async

    /// Store a received notification to local CoreData.
    func store(notification: AppNotification)

    /// Mark a notification as read.
    func markRead(id: UUID)
}

// MARK: - UNUserNotifications implementation

final class LocalNotificationService: NSObject, NotificationServiceProtocol,
                                       UNUserNotificationCenterDelegate {

    private let center = UNUserNotificationCenter.current()
    private let dailyReminderID = "rs.daily.reminder"

    override init() {
        super.init()
        center.delegate = self
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Daily reminder

    func scheduleDailyReminder(at time: Date, message: String) async throws {
        await cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "ReceiptSnap Reminder"
        content.body  = message
        content.sound = .default
        content.badge = 1

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let req = UNNotificationRequest(identifier: dailyReminderID,
                                         content: content, trigger: trigger)
        try await center.add(req)
    }

    func cancelDailyReminder() async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }

    // MARK: - Budget alert

    func scheduleBudgetAlert(budget: Budget) async throws {
        let notifID = "rs.budget.alert.\(budget.id.uuidString)"
        let content = UNMutableNotificationContent()

        if budget.isOverBudget {
            content.title = "Budget Exceeded 🚨"
            content.body  = "You've exceeded your \(budget.period) budget of $\(String(format: "%.0f", budget.monthlyLimit))."
        } else {
            let pct = Int(budget.alertThreshold * 100)
            content.title = "Budget Alert – \(pct)% Used"
            content.body  = "You've used \(pct)% of your \(budget.period) budget."
        }
        content.sound = .default

        // Fire immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req = UNNotificationRequest(identifier: notifID, content: content, trigger: trigger)
        try await center.add(req)
    }

    // MARK: - Utilities

    func cancelAll() async {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    func store(notification: AppNotification) {
        // Persist to CoreData in a background context
        PersistenceController.shared.performBackgroundTask { ctx in
            let entity = CDNotification(context: ctx)
            entity.populate(from: notification)
        }
    }

    func markRead(id: UUID) {
        let ctx = PersistenceController.shared.viewContext
        let req = CDNotification.fetchRequest(for: "")   // fallback; real impl uses userId
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = try? ctx.fetch(req).first {
            obj.isRead = true
            PersistenceController.shared.save()
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                  willPresent notification: UNNotification,
                                  withCompletionHandler completionHandler: @escaping
                                  (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
