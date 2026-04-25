import SwiftUI

struct MainTabView: View {

    @EnvironmentObject private var appState: AppState

    @State private var selectedTab:    Int  = MainTab.dashboard.rawValue
    @State private var showAddReceipt: Bool = false

    @StateObject private var receiptVM = ReceiptViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {

            Group {
                switch selectedTab {
                case MainTab.dashboard.rawValue:
                    DashboardView()
                case MainTab.receipts.rawValue:
                    ReceiptsListView()
                        .environmentObject(receiptVM)
                case MainTab.notifications.rawValue:
                    NotificationsView(
                        onBudgetFeedbackTap: {
                            selectedTab = MainTab.dashboard.rawValue
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                NotificationCenter.default.post(name: .showBudgetFeedback, object: nil)
                            }
                        },
                        onBudgetAlertTap: {
                            selectedTab = MainTab.dashboard.rawValue
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                NotificationCenter.default.post(name: .showBudgetAlert, object: nil)
                            }
                        },
                        onWeeklyReportTap: {
                            selectedTab = MainTab.dashboard.rawValue
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                NotificationCenter.default.post(name: .showWeeklyReport, object: nil)
                            }
                        },
                        onReceiptTap: { showAddReceipt = true }
                    )
                case MainTab.settings.rawValue:
                    SettingsView()
                default:
                    DashboardView()
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 72)
            }

            BottomNavigationBar(
                selectedTab: $selectedTab,
                onAddTap:    { showAddReceipt = true }
            )
            .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: -4)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddReceipt) {
            AddReceiptView()
                .environmentObject(receiptVM)
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToReceipts)) { _ in
            selectedTab = MainTab.receipts.rawValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToDashboard)) { _ in
            selectedTab = MainTab.dashboard.rawValue
        }
    }
}


#Preview {
    MainTabView()
        .environmentObject({
            let s = AppState()
            s.signIn(user: AppUser(uid: "preview", email: "alex@demo.com", displayName: "Alex Smith"))
            return s
        }())
}
