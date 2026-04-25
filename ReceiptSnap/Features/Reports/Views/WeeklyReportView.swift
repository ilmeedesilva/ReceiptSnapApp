
import SwiftUI

struct WeeklyReportView: View {

    let report: WeeklyReportData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    totalSpentCard
                    dailyChartCard
                    topCategoriesCard
                    highValueItemsCard

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .rsScreenBackground()

            navBar
        }
        .navigationBarHidden(true)
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

    // MARK: - Total spent card

    private var totalSpentCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Weekly Report")
                .font(.system(size: AppTheme.Font.title, weight: .bold))
                .foregroundColor(.rsTextPrimary)

            Text("\(report.dateRange.uppercased()), \(report.year)")
                .font(.system(size: AppTheme.Font.caption, weight: .medium))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.3)

            Spacer().frame(height: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text("Total Spent")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)

                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                    Text("$\(String(format: "%.2f", report.totalSpent))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.rsTextPrimary)

                    if let pct = report.vsLastWeek {
                        HStack(spacing: 3) {
                            Image(systemName: pct >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 11, weight: .bold))
                            Text("\(abs(Int(pct)))%")
                                .font(.system(size: AppTheme.Font.body, weight: .bold))
                        }
                        .foregroundColor(pct <= 0 ? .rsForestGreen : .rsError)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background((pct <= 0 ? Color.rsForestGreen : Color.rsError).opacity(0.1))
                        .cornerRadius(AppTheme.Radius.pill)
                    }
                }

                if let amount = report.vsLastWeekAmount {
                    Text("vs $\(String(format: "%.2f", abs(amount) + report.totalSpent)) last week")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
            }
            .rsCardStyle()
        }
    }

    // MARK: - Daily spending chart

    private var dailyChartCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Daily Spending")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            let maxAmount = report.dailySpending.map(\.amount).max() ?? 1
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(report.dailySpending) { day in
                    DailyBar(day: day, maxAmount: maxAmount)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 130)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.rsLightGreen.opacity(0.3))
            .cornerRadius(AppTheme.Radius.md)
        }
        .rsCardStyle()
    }

    // MARK: - Top categories

    private var topCategoriesCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Top Categories")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(report.topCategories) { cat in
                    VStack(spacing: 6) {
                        HStack(spacing: AppTheme.Spacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                    .fill(Color(hex: cat.colorHex).opacity(0.15))
                                    .frame(width: 38, height: 38)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: cat.colorHex))
                            }

                            Text(cat.name)
                                .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                .foregroundColor(.rsTextPrimary)

                            Spacer()

                            Text("$\(String(format: "%.2f", cat.amount))")
                                .font(.system(size: AppTheme.Font.body, weight: .bold))
                                .foregroundColor(.rsTextPrimary)
                        }

                        VStack(alignment: .leading, spacing: 3) {
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
                            .padding(.leading, 54)

                            Text(cat.percentText)
                                .font(.system(size: AppTheme.Font.caption))
                                .foregroundColor(.rsTextMuted)
                                .padding(.leading, 54)
                        }
                    }
                }
            }
        }
        .rsCardStyle()
    }

    // MARK: - High value items

    private var highValueItemsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("High Value Items")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            VStack(spacing: 0) {
                ForEach(Array(report.highValueItems.enumerated()), id: \.element.id) { i, item in
                    HStack(spacing: AppTheme.Spacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .fill(Color.rsDivider)
                                .frame(width: 40, height: 40)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.rsTextSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                .foregroundColor(.rsTextPrimary)
                            Text(item.subtitle)
                                .font(.system(size: AppTheme.Font.caption))
                                .foregroundColor(.rsTextSecondary)
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", item.amount))")
                            .font(.system(size: AppTheme.Font.body, weight: .bold))
                            .foregroundColor(.rsTextPrimary)
                    }
                    .padding(.vertical, AppTheme.Spacing.sm + 4)

                    if i < report.highValueItems.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .rsCardStyle()
    }
}


private struct DailyBar: View {

    let day:       DailyAmount
    let maxAmount: Double
    private let maxBarHeight: CGFloat = 90

    private var barHeight: CGFloat {
        guard maxAmount > 0 else { return 6 }
        return max(CGFloat(day.amount / maxAmount) * maxBarHeight, day.amount > 0 ? 6 : 0)
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
            if day.amount > 0 {
                RoundedRectangle(cornerRadius: 4)
                    .fill(barColor)
                    .frame(width: 24, height: barHeight)
                    .animation(.easeOut(duration: 0.5), value: barHeight)
            } else {
                Spacer().frame(height: 6)
            }
            Text(day.day)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxBarHeight + 20)
    }
}


#Preview {
    NavigationStack {
        WeeklyReportView(report: WeeklyReportData.mockWeeks()[1])
    }
}
