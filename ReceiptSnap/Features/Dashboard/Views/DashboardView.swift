import SwiftUI

struct DashboardView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel       = DashboardViewModel()
    @StateObject private var budgetViewModel = BudgetViewModel()
    @StateObject private var reportsViewModel = ReportsViewModel()

    @State private var budgetPath   = NavigationPath()
    @State private var showProfile  = false

    var body: some View {
        NavigationStack(path: $budgetPath) {
            dashboardContent
                .navigationBarHidden(true)
                .navigationDestination(for: BudgetRoute.self) { route in
                    budgetDestination(for: route)
                }
        }
        .onAppear { wireBudgetCallbacks() }
        .sheet(isPresented: $showProfile) {
            UserProfileView()
        }
    }


    private var dashboardContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppTheme.Spacing.lg) {

                DashboardHeaderView(
                    userName:     appState.currentUser?.firstName ?? "User",
                    onProfileTap: { showProfile = true }
                )

                BudgetSectionView(
                    budget:          viewModel.budget,
                    onSetBudget:     { budgetPath.append(BudgetRoute.setBudget) },
                    onBudgetHistoryTap: { budgetPath.append(BudgetRoute.budgetHistory) },
                    onBudgetCardTap: {
                        guard viewModel.budget != nil else { return }
                        budgetPath.append(BudgetRoute.budgetOverview)
                    }
                )

                TotalSpendingCardView(totalSpending: viewModel.totalSpending)

                SpendingByCategoryView(categories: viewModel.spendingCategories)

                QuickSummaryView(
                    categories: viewModel.spendingCategories,
                    onSeeAll:   { budgetPath.append(BudgetRoute.expenseSummary) }
                )

                ReportsSectionView(
                    reports:     viewModel.reports,
                    onSeeAll:    { budgetPath.append(BudgetRoute.reports) },
                    onReportTap: { report in
                        if report.badge.contains("WEEKLY") {
                            budgetPath.append(BudgetRoute.weeklyReport(dateRange: report.dateRange))
                        } else {
                            budgetPath.append(BudgetRoute.monthlyReport(month: report.dateRange))
                        }
                    }
                )

                RecentReceiptsListView(
                    receipts: viewModel.recentReceipts,
                    onSeeAll: { NotificationCenter.default.post(name: .switchToReceipts, object: nil) }
                )

                Spacer().frame(height: AppTheme.Spacing.sm)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)
        }
        .rsScreenBackground()
        .task {
            await viewModel.loadDashboard(userId: appState.userId)
            await reportsViewModel.loadReports(userId: appState.userId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .receiptAdded)) { _ in
            Task {
                await viewModel.loadDashboard(userId: appState.userId)
                await reportsViewModel.loadReports(userId: appState.userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .receiptsChanged)) { _ in
            Task {
                await viewModel.loadDashboard(userId: appState.userId)
                await reportsViewModel.loadReports(userId: appState.userId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBudgetFeedback)) { _ in
            if viewModel.budget != nil { budgetPath.append(BudgetRoute.budgetFeedback) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showBudgetAlert)) { _ in
            budgetPath.append(BudgetRoute.budgetExceeded)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showWeeklyReport)) { _ in
            budgetPath.append(BudgetRoute.reports)
        }
    }


    @ViewBuilder
    private func budgetDestination(for route: BudgetRoute) -> some View {
        switch route {

        case .setBudget:
            SetBudgetView(
                onSaved:      { budgetPath.append(BudgetRoute.budgetSetSuccess) },
                onViewHistory: { budgetPath.append(BudgetRoute.budgetHistory) }
            )
            .environmentObject(budgetViewModel)

        case .budgetOverview:
            if let budget = viewModel.budget {
                BudgetOverviewView(
                    budget:         budget,
                    onEditBudget:   { budgetPath.append(BudgetRoute.editBudget(id: budget.id)) },
                    onViewHistory:  { budgetPath.append(BudgetRoute.budgetHistory) },
                    onBudgetCardTap: {
                        let dest: BudgetRoute = budget.isOverBudget
                            ? .budgetExceeded
                            : .budgetFeedback
                        budgetPath.append(dest)
                    }
                )
                .environmentObject(budgetViewModel)
            }

        case .editBudget(let id):
            if let budget = budgetViewModel.budget(for: id) ?? (viewModel.budget?.id == id ? viewModel.budget : nil) {
                EditBudgetView(
                    budget:    budget,
                    onSaved:   {
                    
                        budgetPath.removeLast()
                    },
                    onDeleted: { budgetPath.append(BudgetRoute.budgetDeleteSuccess) }
                )
                .environmentObject(budgetViewModel)
            }

        case .budgetHistory:
            BudgetHistoryView { budget in
                budgetPath.append(BudgetRoute.budgetDetail(id: budget.id))
            }
                .environmentObject(budgetViewModel)
                .environmentObject(appState)

        case .budgetDetail(let id):
            if let budget = budgetViewModel.budget(for: id) {
                BudgetDetailView(
                    budget: budget,
                    onEditBudget: budgetViewModel.isEditable(budget)
                        ? { budgetPath.append(BudgetRoute.editBudget(id: budget.id)) }
                        : nil
                )
                .environmentObject(budgetViewModel)
            }

        case .budgetFeedback:
            if let budget = viewModel.budget {
                BudgetFeedbackView(
                    budget:          budget,
                    onViewDashboard: { budgetPath = NavigationPath() },
                    onDismiss:       { budgetPath.removeLast() }
                )
            }

        case .budgetExceeded:
            BudgetExceededView(
                onEditBudget:      {
                    if let budget = viewModel.budget {
                        budgetPath.append(BudgetRoute.editBudget(id: budget.id))
                    }
                },
                onBackToDashboard: { budgetPath = NavigationPath() }
            )

        case .budgetSetSuccess:
            BudgetSetSuccessView(
                onContinue: { budgetPath = NavigationPath() }
            )

        case .budgetDeleteSuccess:
            BudgetDeleteSuccessView(
                onBackToDashboard: { budgetPath = NavigationPath() }
            )

        case .expenseSummary:
            ExpenseSummaryView()
                .environmentObject(appState)

        case .reports:
            ReportsView(
                onWeeklyTap:  { budgetPath.append(BudgetRoute.weeklyReport(dateRange: $0.dateRange)) },
                onMonthlyTap: { budgetPath.append(BudgetRoute.monthlyReport(month: $0.displayLabel)) }
            )
            .environmentObject(reportsViewModel)

        case .weeklyReport(let dateRange):
            if let data = reportsViewModel.weeklyReport(for: dateRange) ?? reportsViewModel.pastWeeks.first {
                WeeklyReportView(report: data)
            }

        case .monthlyReport(let month):
            if let data = reportsViewModel.monthlyReport(for: month) ?? reportsViewModel.monthlyReports.first {
                MonthlyReportView(initialMonth: data)
                    .environmentObject(reportsViewModel)
            }
        }
    }

    private func wireBudgetCallbacks() {
        budgetViewModel.onBudgetSaved = { budget in
            var updatedBudget = budget
            updatedBudget.currentSpending = viewModel.totalSpending
            viewModel.budget = updatedBudget

            Task { await viewModel.loadDashboard(userId: appState.userId) }
        }
        budgetViewModel.onBudgetDeleted = {
            viewModel.clearBudget(userId: appState.userId ?? "")
            Task { await viewModel.loadDashboard(userId: appState.userId) }
        }
    }
}


private struct DashboardHeaderView: View {

    let userName:    String
    let onProfileTap: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.rsForestGreen)
                Text("ReceiptSnap")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.rsDeepGreen)
            }
            Spacer()

            Button(action: onProfileTap) {
                ZStack {
                    Circle()
                        .fill(Color.rsLightGreen)
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.fill")
                        .foregroundColor(.rsForestGreen)
                        .font(.system(size: 18))
                }
            }
        }
    }
}


#Preview {
    DashboardView()
        .environmentObject({
            let s = AppState()
            s.signIn(user: AppUser(uid: "preview", email: "alex@demo.com", displayName: "Alex Smith"))
            return s
        }())
}
