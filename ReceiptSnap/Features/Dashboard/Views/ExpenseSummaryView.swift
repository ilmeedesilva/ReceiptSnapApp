
import SwiftUI

struct ExpenseSummaryView: View {

    @StateObject private var viewModel = ExpenseSummaryViewModel()
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    modeToggle

                    if viewModel.summaryMode == .monthly {
                        monthlyContent
                    } else {
                        sharedContent
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .rsScreenBackground()

            navBar
        }
        .navigationBarHidden(true)
        .task { await viewModel.loadSummary(userId: appState.userId) }
        .onReceive(NotificationCenter.default.publisher(for: .receiptsChanged)) { _ in
            Task { await viewModel.loadSummary(userId: appState.userId) }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.summaryMode)
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
            Text("Expense Summary")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    // MARK: - Mode toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(SummaryMode.allCases) { mode in
                let isSelected = viewModel.summaryMode == mode
                Button { viewModel.summaryMode = mode } label: {
                    Text(mode.rawValue)
                        .font(.system(size: AppTheme.Font.body, weight: .semibold))
                        .foregroundColor(isSelected ? .rsDeepGreen : .rsTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.white : Color.clear)
                        .cornerRadius(AppTheme.Radius.md)
                }
            }
        }
        .padding(3)
        .background(Color.rsDivider)
        .cornerRadius(AppTheme.Radius.md + 2)
    }

    // MARK: - Monthly content

    private var monthlyContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            monthlyOverviewCard
            weeklyChartCard(data: viewModel.monthlyWeekly)
            categoryBreakdownCard(categories: viewModel.monthlyCategories)
        }
        .transition(.opacity)
    }

    private var monthlyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Monthly Overview")
                .font(.system(size: AppTheme.Font.caption, weight: .medium))
                .foregroundColor(.rsTextSecondary)

            Text("Total Spent This Month")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                .foregroundColor(.rsTextPrimary)

            Text("$\(String(format: "%.2f", viewModel.monthlyTotal))")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.rsForestGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsCardStyle()
    }

    // MARK: - Shared content

    private var sharedContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            sharedTotalCard
            othersPaidCard
            weeklyChartCard(data: viewModel.sharedWeekly)
            categoryBreakdownCard(categories: viewModel.sharedCategories)
        }
        .transition(.opacity)
    }

    private var sharedTotalCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL SPENDING")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            Text("$\(String(format: "%.2f", viewModel.sharedTotal))")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.rsTextPrimary)

            Text("Your total spending with others")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .rsCardStyle()
    }

    private var othersPaidCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 38, height: 38)
                Image(systemName: "arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.rsForestGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("OTHERS PAID")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Text("$\(String(format: "%.2f", viewModel.othersPaid))")
                    .font(.system(size: AppTheme.Font.title, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
            }
            Spacer()
        }
        .rsCardStyle()
    }

    // MARK: - Weekly chart (shared between modes)

    private func weeklyChartCard(data: [WeeklySpend]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Weekly Spending")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            WeeklyBarChart(data: data)
                .frame(height: 120)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(Color.rsLightGreen.opacity(0.3))
                .cornerRadius(AppTheme.Radius.md)
        }
        .rsCardStyle()
    }

    // MARK: - Category breakdown (shared between modes)

    private func categoryBreakdownCard(categories: [CategoryExpense]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Category Breakdown")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, item in
                    CategoryExpenseRow(item: item)

                    if index < categories.count - 1 {
                        Divider().padding(.leading, 60)
                    }
                }
            }
        }
        .rsCardStyle()
    }
}


private struct WeeklyBarChart: View {

    let data: [WeeklySpend]

    private var maxAmount: Double {
        data.map(\.amount).max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(data) { week in
                WeeklyBar(week: week, maxAmount: maxAmount)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct WeeklyBar: View {

    let week:      WeeklySpend
    let maxAmount: Double

    private let maxBarHeight: CGFloat = 80

    private var barHeight: CGFloat {
        max(CGFloat(week.amount / maxAmount) * maxBarHeight, 6)
    }

    private var barColor: Color {
        let ratio = week.amount / maxAmount
        switch ratio {
        case 0.7...: return Color.rsDeepGreen
        case 0.4...: return Color.rsForestGreen
        default:     return Color(hex: "A8C5B5")
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 5)
                .fill(barColor)
                .frame(width: 28, height: barHeight)
                .animation(.easeOut(duration: 0.5), value: barHeight)
            Text(week.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxBarHeight + 20)
    }
}


private struct CategoryExpenseRow: View {

    let item: CategoryExpense

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Colored icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(Color(hex: item.category.colorHex).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.category.icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: item.category.colorHex))
                }

                Text(item.displayLabel)
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)

                Spacer()

                Text("$\(String(format: "%.2f", item.amount))")
                    .font(.system(size: AppTheme.Font.body, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.rsDivider)
                        .frame(height: 5)
                    Capsule()
                        .fill(Color(hex: item.category.colorHex))
                        .frame(width: geo.size.width * CGFloat(item.fraction), height: 5)
                        .animation(.easeOut(duration: 0.6), value: item.fraction)
                }
            }
            .frame(height: 5)
            .padding(.leading, 56)   // align with text
        }
        .padding(.vertical, AppTheme.Spacing.sm + 4)
    }
}


#Preview {
    NavigationStack {
        ExpenseSummaryView()
    }
}
