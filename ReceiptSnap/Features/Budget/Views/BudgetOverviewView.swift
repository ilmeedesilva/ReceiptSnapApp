
import SwiftUI

struct BudgetOverviewView: View {

    let budget: Budget
    let onEditBudget: () -> Void
    let onViewHistory: () -> Void
    let onBudgetCardTap: () -> Void   // routes to feedback or exceeded based on status

    @EnvironmentObject private var budgetVM: BudgetViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 48)

                    // Main budget card (tappable)
                    Button(action: onBudgetCardTap) {
                        mainBudgetCard
                    }
                    .buttonStyle(.plain)

                    // Edit Budget button
                    Button(action: onEditBudget) {
                        Text("Edit Budget")
                            .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Height.button)
                            .background(Color.rsDeepGreen)
                            .cornerRadius(AppTheme.Radius.button)
                    }

                    // 7-day spending trend chart
                    spendingTrendCard

                    // Previous months section
                    previousMonthsSection

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .task { await budgetVM.loadOverviewData(userId: appState.userId ?? "") }
        .onReceive(NotificationCenter.default.publisher(for: .receiptsChanged)) { _ in
            Task { await budgetVM.loadOverviewData(userId: appState.userId ?? "") }
        }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("Budget Overview")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    // MARK: - Main budget card

    private var mainBudgetCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // "MONTHLY BUDGET" label + status badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MONTHLY BUDGET")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                    Text("$\(Int(budget.monthlyLimit))")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.rsDeepGreen)
                }
                Spacer()
                Text(budget.isOverBudget ? "Budget exceeded" : "Within budget")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(budget.isOverBudget ? .rsError : .rsForestGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        budget.isOverBudget
                            ? Color.rsError.opacity(0.1)
                            : Color.rsLightGreen
                    )
                    .cornerRadius(AppTheme.Radius.pill)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rsBorder)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(budget.isOverBudget ? Color.rsError : Color.rsForestGreen)
                        .frame(width: geo.size.width * budget.percentConsumed, height: 8)
                        .animation(.easeInOut(duration: 0.6), value: budget.percentConsumed)
                }
            }
            .frame(height: 8)

            // Spent | Remaining mini cards
            HStack(spacing: AppTheme.Spacing.sm) {
                budgetStatMini(label: "SPENT",     value: "$\(Int(budget.currentSpending))")
                Divider().frame(height: 36)
                budgetStatMini(label: "REMAINING", value: "$\(Int(max(budget.remaining, 0)))")
            }
            .padding(AppTheme.Spacing.sm)
            .background(Color.rsDivider)
            .cornerRadius(AppTheme.Radius.sm)
        }
        .rsCardStyle()
    }

    private func budgetStatMini(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                .foregroundColor(.rsTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Spending trend chart (7 days)

    private var spendingTrendCard: some View {
        let maxAmt = budgetVM.weeklyTrend.map(\.amount).max() ?? 1

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("SPENDING TREND")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Spacer()
                Text("Last 7 days")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextMuted)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(budgetVM.weeklyTrend) { day in
                    TrendBarView(day: day, maxAmount: maxAmt)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.rsLightGreen.opacity(0.35))
            .cornerRadius(AppTheme.Radius.md)
        }
        .rsCardStyle()
    }

    // MARK: - Previous months

    private var previousMonthsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("PREVIOUS MONTHS")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Spacer()
                Button("See All") { onViewHistory() }
                    .font(.system(size: AppTheme.Font.body, weight: .medium))
                    .foregroundColor(.rsForestGreen)
            }

            ForEach(budgetVM.budgetHistory.prefix(2)) { item in
                PreviousMonthCard(item: item)
            }
        }
    }
}


private struct TrendBarView: View {

    let day: DailySpending
    let maxAmount: Double

    private let maxBarHeight: CGFloat = 80

    private var barHeight: CGFloat {
        max(CGFloat(day.amount / maxAmount) * maxBarHeight, 6)
    }

    private var barColor: Color {
        let ratio = day.amount / maxAmount
        switch ratio {
        case 0.7...: return Color.rsDeepGreen
        case 0.4...: return Color.rsForestGreen
        default:     return Color(hex: "A8C5B5")
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 4)
                .fill(barColor)
                .frame(width: 26, height: barHeight)
                .animation(.easeOut(duration: 0.5), value: barHeight)
            Text(day.dayLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxBarHeight + 20)
    }
}


private struct PreviousMonthCard: View {

    let item: BudgetHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(item.period)
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Text(item.statusLabel)
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(item.isOverBudget ? .rsError : .rsForestGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.isOverBudget ? Color.rsError.opacity(0.1) : Color.rsLightGreen)
                    .cornerRadius(AppTheme.Radius.pill)
            }

            HStack(spacing: AppTheme.Spacing.xl) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BUDGET")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                    Text("$\(Int(item.totalBudget))")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("SPENT")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                    Text("$\(Int(item.actualSpend))")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                }
                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.rsBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(item.isOverBudget ? Color.rsError : Color.rsForestGreen)
                        .frame(width: geo.size.width * min(item.spendingProgress, 1), height: 6)
                }
            }
            .frame(height: 6)
        }
        .rsCardStyle()
    }
}


#Preview {
    NavigationStack {
        BudgetOverviewView(
            budget: Budget.mock(),
            onEditBudget: {},
            onViewHistory: {},
            onBudgetCardTap: {}
        )
        .environmentObject(BudgetViewModel())
    }
}
