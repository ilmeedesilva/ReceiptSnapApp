import Foundation

final class ServiceLocator {

    static let shared = ServiceLocator()
    private init() {}

    lazy var authService: AuthServiceProtocol = FirebaseAuthService()
    lazy var biometricService: BiometricServiceProtocol = BiometricService()
    lazy var keychainService: KeychainService = KeychainService.shared
    lazy var persistence: PersistenceController = PersistenceController.shared
    lazy var receiptService: ReceiptServiceProtocol = FirebaseReceiptService()
    lazy var budgetService: BudgetServiceProtocol = FirebaseBudgetService()
    lazy var ocrService: OCRServiceProtocol = VisionOCRService()
    lazy var splitService: SplitService = SplitService()
    lazy var notificationService: NotificationServiceProtocol = LocalNotificationService()
    lazy var locationService: LocationServiceProtocol = LocationService()
    lazy var calendarService: CalendarServiceProtocol = EventKitCalendarService()
    lazy var reportService: ReportServiceProtocol = ReportService()
    lazy var searchService: SearchService = SearchService()
}