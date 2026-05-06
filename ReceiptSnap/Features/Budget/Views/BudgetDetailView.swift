import SwiftUI

struct BudgetDetailView: View {

    let budget: Budget
    let onEditBudget: (() -> Void)?

    @EnvironmentObject private var budgetVM: BudgetViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var isUpcoming: Bool {
        budgetVM.isUpcoming(budget)
    }

    private var remainingValue: Double {
        max(budget.remaining, 0)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 48)

                    summaryCard
                    metricsCard

                    if isUpcoming {
                        upcomingInfoCard
                    } else {
                        progressCard
                    }

                    if let onEditBudget {
                        Button(action: onEditBudget) {
                            Text("Edit Budget")
                                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppTheme.Height.button)
                                .background(Color.rsDeepGreen)
                                .cornerRadius(AppTheme.Radius.button)
                        }
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .receiptsChanged)) { _ in
            Task { await budgetVM.loadBudgetHistory(userId: appState.userId ?? "") }
        }
    }

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("Budget Details")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("PERIOD")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            Text(budget.period)
                .font(.system(size: AppTheme.Font.title, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Text(isUpcoming ? "Upcoming budget" : budget.statusText)
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .rsCardStyle()
    }

    private var metricsCard: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            metricTile(title: "BUDGET", value: "$\(Int(budget.monthlyLimit))")
            metricTile(title: "SPENT", value: isUpcoming ? "N/A" : "$\(Int(budget.currentSpending))")
            metricTile(title: "REMAINING", value: isUpcoming ? "N/A" : "$\(Int(remainingValue))")
        }
    }

    private func metricTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                .foregroundColor(.rsTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(Color.rsCardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(Color.rsBorder, lineWidth: 1)
        )
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("SPENDING PROGRESS")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Spacer()
                Text("\(Int(budget.percentConsumed * 100))% used")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(budget.isOverBudget ? .rsError : .rsForestGreen)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rsBorder)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(budget.isOverBudget ? Color.rsError : Color.rsForestGreen)
                        .frame(width: geo.size.width * min(budget.percentConsumed, 1), height: 8)
                }
            }
            .frame(height: 8)

            Text("Spent $\(Int(budget.currentSpending)) out of $\(Int(budget.monthlyLimit)).")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .rsCardStyle()
    }

    private var upcomingInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("UPCOMING PERIOD")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            Text("Spending and remaining values will update once this month starts and receipts are added.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .rsCardStyle()
    }
}

#Preview {
    NavigationStack {
        BudgetDetailView(budget: Budget.mock(), onEditBudget: {})
            .environmentObject(BudgetViewModel())
    }
}