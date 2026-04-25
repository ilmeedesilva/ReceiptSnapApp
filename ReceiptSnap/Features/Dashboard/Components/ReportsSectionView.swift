
import SwiftUI

struct ReportsSectionView: View {

    let reports:     [ReportItem]
    let onSeeAll:    () -> Void
    var onReportTap: ((ReportItem) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // Section header
            HStack {
                Text("Reports")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Button(action: onSeeAll) {
                    Text("See All")
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(.rsForestGreen)
                }
            }

            // Cards row
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(reports) { report in
                    Button { onReportTap?(report) } label: {
                        ReportCard(report: report)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}


private struct ReportCard: View {

    let report: ReportItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Badge row
            HStack(spacing: 4) {
                Text(report.badge)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.rsForestGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Image(systemName: report.badgeIcon)
                    .font(.system(size: 11))
                    .foregroundColor(.rsForestGreen)
            }

            Text(report.dateRange)
                .font(.system(size: AppTheme.Font.caption))
                .foregroundColor(.rsTextSecondary)

            Text(String(format: "$%.2f", report.totalAmount))
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Text(report.footerText)
                .font(.system(size: AppTheme.Font.caption, weight: .medium))
                .foregroundColor(report.footerIsPositive ? .rsForestGreen : .rsTextMuted)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.rsCardBackground)
        .cornerRadius(AppTheme.Radius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ReportsSectionView(reports: ReportItem.mockReports(), onSeeAll: {})
        .padding()
        .background(Color.rsBackgroundGreen)
}
