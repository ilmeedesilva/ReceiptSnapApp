// CalendarServiceProtocol.swift
// ReceiptSnap — EventKit integration for calendar-based receipt reminders.

import Foundation
import EventKit

// MARK: - Matched event

struct CalendarEvent {
    let title:     String
    let startDate: Date
    let endDate:   Date
    let eventID:   String
}

// MARK: - Protocol

protocol CalendarServiceProtocol: AnyObject {
    /// Request EventKit access.
    func requestPermission() async -> Bool

    /// Fetch upcoming events within the given interval, filtered by keywords.
    func fetchEvents(keywords: [String], lookahead days: Int) async throws -> [CalendarEvent]

    /// Schedule a notification to fire `delay` seconds after `event` ends.
    func scheduleReminder(for event: CalendarEvent, delay: TimeInterval) async throws
}

// MARK: - Implementation

final class EventKitCalendarService: CalendarServiceProtocol {

    private let store = EKEventStore()

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            if #available(iOS 17, *) {
                return try await store.requestFullAccessToEvents()
            } else {
                return try await store.requestAccess(to: .event)
            }
        } catch {
            return false
        }
    }

    // MARK: - Fetch events

    func fetchEvents(keywords: [String], lookahead days: Int) async throws -> [CalendarEvent] {
        let now   = Date()
        let end   = Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        let pred  = store.predicateForEvents(withStart: now, end: end, calendars: nil)
        let events = store.events(matching: pred)

        let lower = keywords.map { $0.lowercased() }
        return events
            .filter { event in
                guard let title = event.title else { return false }
                return lower.isEmpty || lower.contains { title.lowercased().contains($0) }
            }
            .map {
                CalendarEvent(title: $0.title ?? "Event",
                               startDate: $0.startDate,
                               endDate: $0.endDate,
                               eventID: $0.eventIdentifier ?? UUID().uuidString)
            }
    }

    // MARK: - Schedule reminder

    func scheduleReminder(for event: CalendarEvent, delay: TimeInterval) async throws {
        let fireDate = event.endDate.addingTimeInterval(delay)
        guard fireDate > Date() else { return }   // event already passed

        let content = UNMutableNotificationContent()
        content.title = "Receipt Reminder"
        content.body  = "You just finished \"\(event.title)\". Remember to log your expenses!"
        content.sound = .default

        let interval = max(fireDate.timeIntervalSinceNow, 1)
        let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let req      = UNNotificationRequest(identifier: "rs.cal.\(event.eventID)",
                                              content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(req)
    }
}

import UserNotifications
