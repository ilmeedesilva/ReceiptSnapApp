
import SwiftUI

struct MonthlyReportView: View {

    let initialMonth:  MonthlyReportData
    @EnvironmentObject private var vm: ReportsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selected: MonthlyReportData

    init(initialMonth: MonthlyReportData) {
        self.initialMonth = initialMonth
        self._selected    = State(initialValue: initialMonth)
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    monthSelector
                    statsHeaderCard
                    categoryBreakdownCard
                    insightsSection

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .rsScreenBackground()

            navBar
        }
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.2), value: selected.id)
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
            Text("Monthly Report")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    // MARK: - Month selector chips

    private var monthSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(vm.monthlyReports) { month in
                    let isSel = selected.id == month.id
                    Button { selected = month } label: {
                        Text(isSel ? month.displayLabel : month.month)
                            .font(.system(size: AppTheme.Font.body, weight: isSel ? .bold : .medium))
                            .foregroundColor(isSel ? .white : .rsTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .background(isSel ? Color.rsForestGreen : Color.rsDivider)
                            .cornerRadius(AppTheme.Radius.pill)
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Stats header card

    private var statsHeaderCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Total Monthly Spending")
                .font(.system(size: AppTheme.Font.caption, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))

            Text("$\(String(format: "%.2f", selected.totalSpent))")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.2))

            HStack(spacing: 0) {
                statPill(label: "Avg / Day",   value: "$\(String(format: "%.2f", selected.avgPerDay))")
                Divider().background(Color.white.opacity(0.2)).frame(height: 32)
                statPill(label: "Receipts",   value: "\(selected.receiptCount) Saved")
                Divider().background(Color.white.opacity(0.2)).frame(height: 32)
                statPill(label: "Budget",      value: "\(selected.budgetUsedPercent)% Used")
            }
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.rsForestGreen, Color.rsDeepGreen],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.Radius.card)
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.7))
                .tracking(0.3)
            Text(value)
                .font(.system(size: AppTheme.Font.body, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category breakdown card

    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Text("Category Breakdown")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            HStack(spacing: AppTheme.Spacing.lg) {
                DonutChart(
                    categories:   selected.categories,
                    centerLabel:  selected.insights.topCategory
                )
                .frame(width: 140, height: 140)

                // Legend
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    ForEach(selected.categories) { cat in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 9, height: 9)
                            Text(cat.name)
                                .font(.system(size: AppTheme.Font.caption))
                                .foregroundColor(.rsTextPrimary)
                            Spacer()
                            Text("$\(String(format: "%.0f", cat.amount))")
                                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                                .foregroundColor(.rsTextPrimary)
                        }
                    }
                }
            }

            Divider()

            // Detailed category rows
            ForEach(Array(selected.categories.enumerated()), id: \.element.id) { i, cat in
                VStack(spacing: 6) {
                    HStack {
                        HStack(spacing: 8) {
                            Circle().fill(Color(hex: cat.colorHex)).frame(width: 9, height: 9)
                            Text(cat.name)
                                .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                .foregroundColor(.rsTextPrimary)
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", cat.amount))")
                            .font(.system(size: AppTheme.Font.body, weight: .bold))
                            .foregroundColor(.rsTextPrimary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.rsDivider).frame(height: 5)
                            Capsule()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: geo.size.width * CGFloat(cat.fraction), height: 5)
                                .animation(.easeOut(duration: 0.6), value: cat.fraction)
                        }
                    }
                    .frame(height: 5)

                    Text(cat.trend)
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if i < selected.categories.count - 1 {
                    Divider()
                }
            }
        }
        .rsCardStyle()
    }

    // MARK: - Insights section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Insights")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                insightCard(
                    icon:     "calendar",
                    iconHex:  "3B82F6",
                    label:    "Most Expensive Day",
                    value:    selected.insights.mostExpensiveDay,
                    subtitle: "$\(String(format: "%.0f", selected.insights.mostExpensiveDayAmount)) spent"
                )
                insightCard(
                    icon:     "arrow.up.right",
                    iconHex:  "8B5CF6",
                    label:    "Top Category",
                    value:    selected.insights.topCategory,
                    subtitle: "\(selected.insights.topCategoryPercent)% of total"
                )
            }
        }
    }

    private func insightCard(icon: String, iconHex: String, label: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color(hex: iconHex).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: iconHex))
            }

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.3)

            Text(value)
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)

            Text(subtitle)
                .font(.system(size: AppTheme.Font.caption))
                .foregroundColor(.rsTextMuted)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}


private struct DonutChart: View {

    let categories: [MonthlyCategory]
    let centerLabel: String

    private struct Arc: Identifiable {
        let id       = UUID()
        let start:   Double
        let end:     Double
        let colorHex: String
    }

    private var arcs: [Arc] {
        let total = categories.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }
        var cursor: Double = 0
        return categories.map { cat in
            let frac  = cat.amount / total
            let arc   = Arc(start: cursor, end: cursor + frac, colorHex: cat.colorHex)
            cursor   += frac
            return arc
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.rsDivider, lineWidth: 22)

            // Coloured arcs
            ForEach(arcs) { arc in
                Circle()
                    .trim(from: arc.start, to: arc.end)
                    .stroke(
                        Color(hex: arc.colorHex),
                        style: StrokeStyle(lineWidth: 22, lineCap: .butt)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.8), value: arc.end)
            }

            // Centre label
            VStack(spacing: 1) {
                Text("Top Category")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.rsTextSecondary)
                Text(centerLabel)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(8)
        }
    }
}


#Preview {
    let vm = ReportsViewModel()
    return NavigationStack {
        MonthlyReportView(initialMonth: MonthlyReportData.mockMonths()[1])
            .environmentObject(vm)
    }
}
