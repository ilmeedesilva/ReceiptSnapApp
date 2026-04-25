
import SwiftUI

struct SpendingByCategoryView: View {

    let categories: [SpendingCategory]

    private var maxAmount: Double {
        categories.map(\.amount).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            Text("Spending by Category")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsTextPrimary)

            // Chart container
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(categories) { category in
                    CategoryBarView(category: category, maxAmount: maxAmount)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.rsLightGreen.opacity(0.35))
            .cornerRadius(AppTheme.Radius.md)
        }
        .rsCardStyle()
    }
}


private struct CategoryBarView: View {

    let category:  SpendingCategory
    let maxAmount: Double

    private let maxBarHeight: CGFloat = 88

    private var barHeight: CGFloat {
        max(CGFloat(category.amount / maxAmount) * maxBarHeight, 8)
    }

    // Taller bars get the darkest shade, shorter bars are muted
    private var barColor: Color {
        let ratio = category.amount / maxAmount
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

            Text(category.shortLabel)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxBarHeight + 20)
    }
}

#Preview {
    SpendingByCategoryView(categories: SpendingCategory.mockCategories())
        .padding()
        .background(Color.rsBackgroundGreen)
}
