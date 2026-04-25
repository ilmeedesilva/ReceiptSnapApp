
import SwiftUI

struct ReportsView: View {

    @EnvironmentObject private var vm: ReportsViewModel
    @Environment(\.dismiss) private var dismiss

    // Callbacks so Dashboard's NavigationStack drives the push.
    let onWeeklyTap:  (WeeklyReportData)  -> Void
    let onMonthlyTap: (MonthlyReportData) -> Void

    /// Currently highlighted month cell in the calendar picker.
    @State private var selectedPickerMonth: MonthPickerItem? = nil

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    modeToggle

                    if vm.reportMode == .weekly {
                        weeklyContent
                    } else {
                        monthlyContent
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .rsScreenBackground()

            navBar
        }
        .navigationBarHidden(true)
        .task { await vm.loadReports() }
        .animation(.easeInOut(duration: 0.2), value: vm.reportMode)
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
            Text("Reports")
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
            ForEach(ReportMode.allCases) { mode in
                let sel = vm.reportMode == mode
                Button { vm.reportMode = mode } label: {
                    Text(mode.rawValue)
                        .font(.system(size: AppTheme.Font.body, weight: .semibold))
                        .foregroundColor(sel ? .rsDeepGreen : .rsTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(sel ? Color.white : Color.clear)
                        .cornerRadius(AppTheme.Radius.md)
                }
            }
        }
        .padding(3)
        .background(Color.rsDivider)
        .cornerRadius(AppTheme.Radius.md + 2)
    }

    // MARK: - Weekly content

    private var weeklyContent: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Active report
            if let active = vm.activeWeek {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    sectionLabel("ACTIVE REPORT")

                    Button { onWeeklyTap(active) } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                    .fill(Color.rsLightGreen)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.rsForestGreen)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(active.dateRange)
                                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                    .foregroundColor(.rsTextPrimary)
                                Text(active.displayStatus)
                                    .font(.system(size: AppTheme.Font.caption))
                                    .foregroundColor(.rsTextSecondary)
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", active.totalSpent))")
                                .font(.system(size: AppTheme.Font.body, weight: .bold))
                                .foregroundColor(.rsForestGreen)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.rsTextMuted)
                        }
                        .rsCardStyle()
                    }
                    .buttonStyle(.plain)
                }
            }

            // Past weeks
            if !vm.pastWeeks.isEmpty {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    sectionLabel("PAST WEEKS")

                    VStack(spacing: 0) {
                        ForEach(Array(vm.pastWeeks.enumerated()), id: \.element.id) { i, week in
                            Button { onWeeklyTap(week) } label: {
                                PastWeekRow(week: week)
                            }
                            .buttonStyle(.plain)

                            if i < vm.pastWeeks.count - 1 {
                                Divider().padding(.leading, AppTheme.Spacing.md)
                            }
                        }
                    }
                    .background(Color.rsCardBackground)
                    .cornerRadius(AppTheme.Radius.card)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                }
            }

            // Monthly spend summary card
            monthlySpendCard
        }
        .transition(.opacity)
    }

    private var monthlySpendCard: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Total Monthly Spend")
                    .font(.system(size: AppTheme.Font.caption, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.8))

                Text("$\(String(format: "%.2f", vm.totalMonthlySpend))")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.3)).frame(height: 6)
                        Capsule().fill(Color.white)
                            .frame(width: geo.size.width * vm.monthlyBudgetUsed, height: 6)
                    }
                }
                .frame(height: 6)

                Text("\(Int(vm.monthlyBudgetUsed * 100))% of your monthly budget of $4,200 used")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(Color.white.opacity(0.8))
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color.rsForestGreen, Color.rsDeepGreen],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppTheme.Radius.card)

            Image(systemName: "arrow.up.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.6))
                .padding(AppTheme.Spacing.md)
        }
    }

    // MARK: - Monthly content (calendar picker)

    private var monthlyContent: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            yearSelector
            monthGrid
            if let picked = selectedPickerMonth {
                monthSummaryCard(for: picked)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .transition(.opacity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPickerMonth?.id)
    }

    private var yearSelector: some View {
        HStack {
            Button {
                if vm.selectedYear > (vm.availableYears.first ?? 2024) {
                    vm.selectedYear -= 1
                    selectedPickerMonth = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 44, height: 44)
            }

            Spacer()
            Text("\(vm.selectedYear)")
                .font(.system(size: AppTheme.Font.title, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()

            Button {
                if vm.selectedYear < (vm.availableYears.last ?? 2026) {
                    vm.selectedYear += 1
                    selectedPickerMonth = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 44, height: 44)
            }
        }
    }

    private var monthGrid: some View {
        let items = vm.monthItems(for: vm.selectedYear)
        let cols  = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 3)

        return LazyVGrid(columns: cols, spacing: AppTheme.Spacing.sm) {
            ForEach(items) { item in
                MonthCell(
                    item:         item,
                    isSelected:   selectedPickerMonth?.id == item.id,
                    hasSelection: selectedPickerMonth != nil
                ) {
                    // First tap highlights; second tap on same month navigates immediately.
                    if selectedPickerMonth?.id == item.id,
                       let data = vm.monthlyReport(for: "\(item.month) \(item.year)") {
                        onMonthlyTap(data)
                    } else {
                        selectedPickerMonth = item
                    }
                }
            }
        }
    }

    // MARK: - Month summary card (shown after a month is selected)

    private func monthSummaryCard(for item: MonthPickerItem) -> some View {
        let reportData = vm.monthlyReport(for: "\(item.month) \(item.year)")

        return Button {
            if let data = reportData { onMonthlyTap(data) }
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Calendar icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                // Total + receipts
                VStack(alignment: .leading, spacing: 3) {
                    Text("Total for \(item.month)")
                        .font(.system(size: AppTheme.Font.caption, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.8))
                    Text(item.hasData
                         ? "$\(String(format: "%.2f", item.totalSpent))"
                         : "No data")
                        .font(.system(size: AppTheme.Font.headline, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Receipt count + CTA
                VStack(alignment: .trailing, spacing: 3) {
                    if item.hasData {
                        Text("\(item.receiptCount) RECEIPTS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.7))
                            .tracking(0.3)
                    }
                    HStack(spacing: 4) {
                        Text("VIEW LIST")
                            .font(.system(size: AppTheme.Font.caption, weight: .bold))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .opacity(item.hasData ? 1 : 0.5)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Color.rsForestGreen, Color.rsDeepGreen],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(AppTheme.Radius.card)
        }
        .buttonStyle(.plain)
        .disabled(!item.hasData)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: AppTheme.Font.caption, weight: .semibold))
            .foregroundColor(.rsTextSecondary)
            .tracking(0.5)
    }
}


private struct PastWeekRow: View {

    let week: WeeklyReportData

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.rsDivider)
                    .frame(width: 38, height: 38)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 14))
                    .foregroundColor(.rsTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(week.dateRange)
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Text("\(week.receiptCount) Receipts • \(week.displayStatus)")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
            }

            Spacer()

            Text("$\(String(format: "%.2f", week.totalSpent))")
                .font(.system(size: AppTheme.Font.body, weight: .bold))
                .foregroundColor(.rsTextPrimary)

            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundColor(.rsTextMuted)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 4)
    }
}


private struct MonthCell: View {

    let item:         MonthPickerItem
    let isSelected:   Bool
    let hasSelection: Bool
    let onTap:        () -> Void

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        let now = Date()
        return cal.component(.month, from: now) == (Calendar.current.monthSymbols.firstIndex(of: item.month).map { $0 + 1 } ?? 0)
            && cal.component(.year, from: now) == item.year
    }

    private var bgColor: Color {
        if isSelected    { return Color.rsDeepGreen }
        if isCurrentMonth {
            return hasSelection ? Color.rsForestGreen.opacity(0.3) : Color.rsForestGreen
        }
        return Color.rsDivider
    }

    private var textColor: Color {
        if isSelected    { return .white }
        if isCurrentMonth { return hasSelection ? Color.rsForestGreen : .white }
        return .rsTextPrimary
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                Text(item.shortMonth)
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(textColor)

                if item.hasData || isSelected {
                    Circle()
                        .fill(textColor.opacity(0.7))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(bgColor)
            .cornerRadius(AppTheme.Radius.md)
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
    }
}


#Preview {
    let vm = ReportsViewModel()
    return NavigationStack {
        ReportsView(onWeeklyTap: { _ in }, onMonthlyTap: { _ in })
            .environmentObject(vm)
    }
}
