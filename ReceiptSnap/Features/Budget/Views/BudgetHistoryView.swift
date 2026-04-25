
import SwiftUI

struct BudgetHistoryView: View {

    @EnvironmentObject private var budgetVM: BudgetViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showFilterSheet = false
    @State private var selectedSort: SortOption = .latestFirst
    @State private var selectedStatus: StatusFilter = .all
    @State private var selectedYear: Int? = nil

    // MARK: - Filtering + sorting (pure — unit-testable)

    var filteredHistory: [BudgetHistoryItem] {
        var items = budgetVM.budgetHistory

        // Status filter
        switch selectedStatus {
        case .all:         break
        case .underBudget: items = items.filter { !$0.isOverBudget }
        case .overBudget:  items = items.filter { $0.isOverBudget }
        }

        // Year filter
        if let year = selectedYear {
            items = items.filter { $0.period.contains("\(year)") }
        }

        // Sort
        switch selectedSort {
        case .latestFirst:   break // mock data is already latest-first
        case .oldestFirst:   items = items.reversed()
        case .highestSpend:  items = items.sorted { $0.actualSpend > $1.actualSpend }
        case .lowestSpend:   items = items.sorted { $0.actualSpend < $1.actualSpend }
        }

        return items
    }

    var availableYears: [Int] {
        let years = budgetVM.budgetHistory.compactMap { item -> Int? in
            let parts = item.period.split(separator: " ")
            guard let yearStr = parts.last else { return nil }
            return Int(yearStr)
        }
        return Array(Set(years)).sorted(by: >)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.md) {
                    Spacer().frame(height: 48)

                    // Section header
                    HStack {
                        Text("PAST PERIODS")
                            .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                            .foregroundColor(.rsTextSecondary)
                            .tracking(0.5)
                        Spacer()
                        Button { showFilterSheet = true } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 16))
                                .foregroundColor(.rsTextSecondary)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)

                    if filteredHistory.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredHistory) { item in
                            HistoryItemCard(item: item)
                                .padding(.horizontal, AppTheme.Spacing.md)
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
            if budgetVM.budgetHistory.isEmpty {
                await budgetVM.loadOverviewData(userId: appState.userId ?? "")
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(
                selectedSort:   $selectedSort,
                selectedStatus: $selectedStatus,
                selectedYear:   $selectedYear,
                availableYears: availableYears,
                onApply: { showFilterSheet = false }
            )
            .presentationDetents([.medium, .large])
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
            Text("Budget History")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.rsLightGreen)
            Text("No matching records")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}


private struct HistoryItemCard: View {
    let item: BudgetHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.period)
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                    Text("\(item.daysCompleted) days completed")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
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
                    Text("TOTAL BUDGET")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                    Text("$\(Int(item.totalBudget))")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("ACTUAL SPEND")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                    Text("$\(Int(item.actualSpend))")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                }
                Spacer()
            }

            VStack(spacing: 4) {
                HStack {
                    Text("Spending Progress")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                    Spacer()
                    Text("\(Int(min(item.spendingProgress, 1) * 100))%")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(item.isOverBudget ? .rsError : .rsTextSecondary)
                }
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
        }
        .rsCardStyle()
    }
}


private struct FilterSheet: View {

    @Binding var selectedSort:   SortOption
    @Binding var selectedStatus: StatusFilter
    @Binding var selectedYear:   Int?
    let availableYears: [Int]
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sheet handle + header
            HStack {
                Button {
                    selectedSort   = .latestFirst
                    selectedStatus = .all
                    selectedYear   = nil
                } label: {
                    Text("Reset")
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(.rsForestGreen)
                }
                Spacer()
                Text("Filter Budget history")
                    .font(.system(size: AppTheme.Font.headline, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Button { onApply() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                        .foregroundColor(.rsTextSecondary)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

                    // Sort By
                    filterSection(title: "SORT BY") {
                        chipGrid(items: Array(SortOption.allCases), selected: selectedSort) {
                            selectedSort = $0
                        }
                    }

                    // Status
                    filterSection(title: "STATUS") {
                        chipGrid(items: Array(StatusFilter.allCases), selected: selectedStatus) {
                            selectedStatus = $0
                        }
                    }

                    // Year
                    filterSection(title: "YEAR") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                yearChip(label: "All", value: nil)
                                ForEach(availableYears, id: \.self) { year in
                                    yearChip(label: "\(year)", value: year)
                                }
                            }
                        }
                    }

                    // Apply button
                    Button(action: onApply) {
                        Text("Apply Filters")
                            .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Height.button)
                            .background(Color.rsDeepGreen)
                            .cornerRadius(AppTheme.Radius.button)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
        }
        .background(Color.rsCardBackground)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            content()
        }
    }

    private func chipGrid<T: Hashable & FilterChipRepresentable>(
        items: [T],
        selected: T,
        onSelect: @escaping (T) -> Void
    ) -> some View {
        FlowLayout(spacing: AppTheme.Spacing.sm) {
            ForEach(items, id: \.hashValue) { item in
                let isSelected = item == selected
                Button { onSelect(item) } label: {
                    Text(item.chipLabel)
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(isSelected ? .white : .rsTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isSelected ? Color.rsForestGreen : Color.rsDivider)
                        .cornerRadius(AppTheme.Radius.pill)
                }
            }
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
}


enum SortOption: String, CaseIterable, Hashable, FilterChipRepresentable {
    case latestFirst  = "Latest First"
    case oldestFirst  = "Oldest First"
    case highestSpend = "Highest Spend"
    case lowestSpend  = "Lowest Spend"
    var chipLabel: String { rawValue }
}

enum StatusFilter: String, CaseIterable, Hashable, FilterChipRepresentable {
    case all         = "All"
    case underBudget = "Under Budget"
    case overBudget  = "Over Budget"
    var chipLabel: String { rawValue }
}

protocol FilterChipRepresentable {
    var chipLabel: String { get }
}


private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        // Simple horizontal scroll fallback — replace with a proper flow layout if needed.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                content()
            }
        }
    }
}


#Preview {
    NavigationStack {
        BudgetHistoryView()
            .environmentObject(BudgetViewModel())
    }
}
