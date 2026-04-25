import Foundation

enum NotificationType: String, Codable, CaseIterable {
    case receiptReminder  = "receiptReminder"
    case locationReminder = "locationReminder"
    case budgetFeedback   = "budgetFeedback"
    case budgetAlert      = "budgetAlert"
    case weeklyReport     = "weeklyReport"
    case dailyReminder    = "dailyReminder"

    var icon: String {
        switch self {
        case .receiptReminder:  return "calendar"
        case .locationReminder: return "mappin.circle.fill"
        case .budgetFeedback:   return "creditcard.fill"
        case .budgetAlert:      return "creditcard.fill"
        case .weeklyReport:     return "chart.bar.fill"
        case .dailyReminder:    return "bell.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .receiptReminder,
             .locationReminder,
             .weeklyReport,
             .dailyReminder:  return "3B82F6"   
        case .budgetFeedback,
             .budgetAlert:    return "1F6F54"  
        }
    }
}

enum NotificationGroup: String {
    case today     = "TODAY"
    case yesterday = "YESTERDAY"
    case thisWeek  = "THIS WEEK"
    case older     = "OLDER"
}

struct AppNotification: Identifiable, Equatable, Codable {

    let id:              UUID
    var userId:          String?        
    let type:            NotificationType
    let title:           String
    let message:         String
    let timestamp:       Date
    var isRead:          Bool
    var relatedEntityId: String?        
    var relatedScreen:   String?        

    init(
        id:              UUID              = UUID(),
        userId:          String?           = nil,
        type:            NotificationType,
        title:           String,
        message:         String,
        timestamp:       Date,
        isRead:          Bool              = false,
        relatedEntityId: String?           = nil,
        relatedScreen:   String?           = nil
    ) {
        self.id              = id
        self.userId          = userId
        self.type            = type
        self.title           = title
        self.message         = message
        self.timestamp       = timestamp
        self.isRead          = isRead
        self.relatedEntityId = relatedEntityId
        self.relatedScreen   = relatedScreen
    }

   
    func relativeTimeLabel(from now: Date = Date()) -> String {
        let diff = now.timeIntervalSince(timestamp)
        let minutes = Int(diff / 60)
        let hours   = Int(diff / 3600)

        if minutes < 60  { return "\(max(minutes, 1))m ago" }
        if hours   < 24  { return "\(hours)h ago" }


        let cal = Calendar.current
        if cal.isDateInYesterday(timestamp) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"  
        return formatter.string(from: timestamp)
    }

    func group(from now: Date = Date()) -> NotificationGroup {
        let cal  = Calendar.current
        let diff = now.timeIntervalSince(timestamp)
        if diff < 86_400 && cal.isDateInToday(timestamp) { return .today     }
        if cal.isDateInYesterday(timestamp)               { return .yesterday }
        if diff < 7 * 86_400                              { return .thisWeek  }
        return .older
    }


    static func mockNotifications() -> [AppNotification] { MockData.notifications }
}
