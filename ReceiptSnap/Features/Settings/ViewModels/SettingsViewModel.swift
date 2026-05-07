import SwiftUI
import UIKit
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {

    @AppStorage("rs_dark_mode") var isDarkMode: Bool = false

    @AppStorage("rs_reminder_time_interval") private var reminderTimeInterval: Double = 20 * 3600

    var reminderTime: Date {
        get { Date(timeIntervalSince1970: reminderTimeInterval) }
        set { reminderTimeInterval = newValue.timeIntervalSince1970 }
    }

    var reminderTimeLabel: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: reminderTime)
    }
}


@MainActor
final class SecurityViewModel: ObservableObject {

    @AppStorage("rs_face_id_enabled")      var isFaceIDEnabled:            Bool = false
    @AppStorage("rs_require_passcode_now") var requirePasscodeImmediately: Bool = true
    @AppStorage("rs_two_fa_enabled")       var isTwoFAEnabled:             Bool = true

    @Published var showFaceIDScanning = false
    @Published var showFaceIDVerified = false
    @Published var showFaceIDSuccess = false

    private let biometricService: BiometricServiceProtocol

    init(biometricService: BiometricServiceProtocol = ServiceLocator.shared.biometricService) {
        self.biometricService = biometricService
    }

    var isFaceIDSimulationEnabled: Bool { biometricService.isSimulationEnabled }

    func toggleFaceID() {
        if isFaceIDEnabled {
            isFaceIDEnabled = false
        } else {
            Task {
                showFaceIDScanning = true
                do {
                    let ok = try await biometricService.authenticate(reason: "Enable Face ID for ReceiptSnap")
                    showFaceIDScanning = false
                    if ok {
                        isFaceIDEnabled = true
                        presentSuccessState()
                    }
                } catch {
                    showFaceIDScanning = false
                    isFaceIDEnabled = true
                    presentSuccessState()
                }
            }
        }
    }

    func startFaceIDReset() {
        showFaceIDScanning = true
        Task {
            _ = try? await biometricService.authenticate(reason: "Reset Face ID for ReceiptSnap")
            showFaceIDScanning = false
            presentSuccessState()
        }
    }

    private func presentSuccessState() {
        showFaceIDVerified = true
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            showFaceIDVerified = false
        }

        showFaceIDSuccess = true
        Task {
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            showFaceIDSuccess = false
        }
    }
}


@MainActor
final class NotificationSettingsViewModel: ObservableObject {

    @AppStorage("rs_daily_reminder")         var isDailyReminderEnabled:  Bool = true
    @AppStorage("rs_reminder_time_interval") private var reminderInterval: Double = 20 * 3600
    @AppStorage("rs_daily_briefing")         var isDailyBriefingEnabled:  Bool = true
    @AppStorage("rs_weekly_summary")         var isWeeklySummaryEnabled:  Bool = false
    @AppStorage("rs_location_alerts")        var isLocationAlertsEnabled: Bool = true
    @AppStorage("rs_calendar_sync")          var isCalendarSyncEnabled:   Bool = true

    @Published var showReminderPicker = false

    private let notificationService: NotificationServiceProtocol
    private let locationService:     LocationServiceProtocol
    private let calendarService:     CalendarServiceProtocol

    init(
        notificationService: NotificationServiceProtocol = ServiceLocator.shared.notificationService,
        locationService:     LocationServiceProtocol     = ServiceLocator.shared.locationService,
        calendarService:     CalendarServiceProtocol     = ServiceLocator.shared.calendarService
    ) {
        self.notificationService = notificationService
        self.locationService     = locationService
        self.calendarService     = calendarService
    }

    var reminderTime: Date {
        get { Date(timeIntervalSince1970: reminderInterval) }
        set {
            reminderInterval = newValue.timeIntervalSince1970
            if isDailyReminderEnabled { scheduleReminder() }
        }
    }

    var reminderTimeLabel: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: reminderTime)
    }

    func requestNotificationPermission() {
        Task {
            let granted = await notificationService.requestPermission()
            if granted && isDailyReminderEnabled { scheduleReminder() }
        }
    }

    func requestLocationPermission() {
        Task { _ = await locationService.requestPermission() }
    }

    func requestCalendarPermission() {
        Task { _ = await calendarService.requestPermission() }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func scheduleReminder() {
        Task {
            try? await notificationService.scheduleDailyReminder(
                at: reminderTime,
                message: "Don't forget to snap your receipts today!"
            )
        }
    }
}


enum ReminderTiming: String, CaseIterable, Identifiable {
    case atEvent        = "At the event"
    case atEventEnd     = "At event end"
    case thirtyMinAfter = "30 minutes after the event"
    var id: String { rawValue }
}

enum EventFilter: String, CaseIterable, Identifiable {
    case allEvents    = "All events"
    case selectedOnly = "Selected events only"
    var id: String { rawValue }
}

@MainActor
final class CalendarSettingsViewModel: ObservableObject {

    @AppStorage("rs_reminder_timing") private var reminderTimingRaw: String = ReminderTiming.atEventEnd.rawValue
    @AppStorage("rs_event_filter")    private var eventFilterRaw:    String = EventFilter.selectedOnly.rawValue

    @Published var selectedEvents: Set<String> = ["Dinner", "Shopping"]

    var reminderTiming: ReminderTiming {
        get { ReminderTiming(rawValue: reminderTimingRaw) ?? .atEventEnd }
        set { reminderTimingRaw = newValue.rawValue }
    }

    var eventFilter: EventFilter {
        get { EventFilter(rawValue: eventFilterRaw) ?? .selectedOnly }
        set { eventFilterRaw = newValue.rawValue }
    }

    var availableEvents: [String] { ["Dinner", "Shopping", "Food Market", "Coffee", "Grocery"] }

    var selectedEventsLabel: String { "\(selectedEvents.count) Selected" }

    var reminderDelay: TimeInterval {
        switch reminderTiming {
        case .atEvent:        return 0
        case .atEventEnd:     return 0
        case .thirtyMinAfter: return 30 * 60
        }
    }
}
