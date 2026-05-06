import SwiftUI

struct BudgetHistoryView: View {

    let onSelectBudget: (Budget) -> Void

    @EnvironmentObject private var budgetVM: BudgetViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedYear: Int? = nil

    private var filteredBudgets: [Budget] {
        let items = budgetVM.budgets
        guard let selectedYear else { return items }
        return items.filter { $0.year == selectedYear }
    }

    private var availableYears: [Int] {
        budgetVM.availableBudgetYears()
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.md) {
                    Spacer().frame(height: 48)

                    headerSection
                        .padding(.horizontal, AppTheme.Spacing.md)

                    yearFilterSection

                    if filteredBudgets.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(filteredBudgets) { budget in
                                Button {
                                    onSelectBudget(budget)
                                } label: {
                                    BudgetActivityCard(
                                        budget: budget,
                                        isEditable: budgetVM.isEditable(budget),
                                        isUpcoming: budgetVM.isUpcoming(budget)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, AppTheme.Spacing.md)
                            }
                        }
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.top, AppTheme.Spacing.sm)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .task {
            if budgetVM.budgets.isEmpty {
                await budgetVM.loadBudgetHistory(userId: appState.userId ?? "")
            }
        }
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
            Text("Budget Activity")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("ALL BUDGETS")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Text("Tap a month to view details")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
            }
            Spacer()
        }
    }

    private var yearFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                yearChip(label: "All", value: nil)
                ForEach(availableYears, id: \.self) { year in
                    yearChip(label: "\(year)", value: year)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    private func yearChip(label: String, value: Int?) -> some View {
        let isSelected = selectedYear == value
        return Button { selectedYear = value } label: {
            Text(label)
                .font(.system(size: AppTheme.Font.body, weight: .medium))
                .foregroundColor(isSelected ? .white : .rsTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.rsForestGreen : Color.rsDivider)
                .cornerRadius(AppTheme.Radius.pill)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.rsLightGreen)
            Text("No budgets found")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

private struct BudgetActivityCard: View {
    let budget: Budget
    let isEditable: Bool
    let isUpcoming: Bool

    private var badgeText: String {
        if isUpcoming { return "Upcoming" }
        if isEditable { return "Editable" }
        return "Locked"
    }

    private var badgeColor: Color {
        if isUpcoming { return .rsDeepGreen }
        return isEditable ? .rsForestGreen : .rsTextSecondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(budget.period)
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                    Text(isUpcoming ? "Spending starts when the month begins" : budget.statusText)
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Text(badgeText)
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor.opacity(0.12))
                    .cornerRadius(AppTheme.Radius.pill)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                budgetValue(title: "BUDGET", value: "$\(Int(budget.monthlyLimit))")
                budgetValue(
                    title: isUpcoming ? "STARTS WITH" : "SPENT",
                    value: isUpcoming ? "$0" : "$\(Int(budget.currentSpending))"
                )
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.rsTextMuted)
            }

            if !isUpcoming {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.rsBorder)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(budget.isOverBudget ? Color.rsError : Color.rsForestGreen)
                            .frame(width: geo.size.width * min(budget.percentConsumed, 1), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .rsCardStyle()
    }

    private func budgetValue(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            Text(value)
                .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                .foregroundColor(.rsTextPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        BudgetHistoryView(onSelectBudget: { _ in })
            .environmentObject(BudgetViewModel())
            .environmentObject(AppState())
    }
}