
import Foundation

final class ServiceLocator {

    static let shared = ServiceLocator()
    private init() {}

    // MARK: - Auth
    // Default: FirebaseAuthService. Switch to MockAuthService() if Firebase SDK not added yet.
    lazy var authService: AuthServiceProtocol = FirebaseAuthService()

    // MARK: - Biometric
    lazy var biometricService: BiometricServiceProtocol = BiometricService()

    // MARK: - Storage
    lazy var keychainService: KeychainService = KeychainService.shared

    // MARK: - CoreData
    /// Shared persistence controller. Swap for PersistenceController(inMemory:true) in tests.
    lazy var persistence: PersistenceController = PersistenceController.shared

    // MARK: - Receipt
    /// Toggle to FirebaseReceiptService() once Firebase Storage/Firestore are configured.
    lazy var receiptService: ReceiptServiceProtocol = MockReceiptService()

    // MARK: - Budget
    /// Toggle to FirebaseBudgetService() once Firestore is configured.
    lazy var budgetService: BudgetServiceProtocol = MockBudgetService()

    // MARK: - OCR
    lazy var ocrService: OCRServiceProtocol = VisionOCRService()

    // MARK: - Split
    lazy var splitService: SplitService = SplitService()

    // MARK: - Notifications
    lazy var notificationService: NotificationServiceProtocol = LocalNotificationService()

    // MARK: - Location
    lazy var locationService: LocationServiceProtocol = LocationService()

    // MARK: - Calendar
    lazy var calendarService: CalendarServiceProtocol = EventKitCalendarService()

    // MARK: - Reports
    lazy var reportService: ReportServiceProtocol = ReportService()

    // MARK: - Search
    lazy var searchService: SearchService = SearchService()
}
