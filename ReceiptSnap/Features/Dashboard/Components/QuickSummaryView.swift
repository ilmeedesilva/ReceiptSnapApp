
import SwiftUI

struct QuickSummaryView: View {

    let categories: [SpendingCategory]
    let onSeeAll:   () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // Section header
            HStack {
                Text("Quick Summary")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Button(action: onSeeAll) {
                    Text("See All")
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(.rsForestGreen)
                }
            }

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(categories) { category in
                        CategorySummaryCard(category: category)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}


private struct CategorySummaryCard: View {

    let category: SpendingCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Icon — colored per category, matching the recent receipts section
            ZStack {
                Circle()
                    .fill(Color(hex: category.category.colorHex).opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.category.colorHex))
                    .font(.system(size: 15))
            }

            Text(category.label)
                .font(.system(size: AppTheme.Font.caption))
                .foregroundColor(.rsTextSecondary)
                .lineLimit(1)

            Text(String(format: "$%.2f", category.amount))
                .font(.system(size: AppTheme.Font.body, weight: .semibold))
                .foregroundColor(.rsTextPrimary)
        }
        .padding(AppTheme.Spacing.md)
        .frame(width: 104)
        .background(Color.rsCardBackground)
        .cornerRadius(AppTheme.Radius.md)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    QuickSummaryView(
        categories: SpendingCategory.mockCategories(),
        onSeeAll:   {}
    )
    .padding()
    .background(Color.rsBackgroundGreen)
}
