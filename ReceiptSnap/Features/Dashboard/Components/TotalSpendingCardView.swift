
import SwiftUI

struct TotalSpendingCardView: View {

    let totalSpending: Double

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            // Gradient background
            LinearGradient(
                colors: [Color.rsDeepGreen, Color.rsForestGreen],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            .cornerRadius(AppTheme.Radius.card)

            // Subtle circle decoration (top-right)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 140, height: 140)
                .offset(x: 220, y: -60)

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {

                Text("Total Spending")
                    .font(.system(size: AppTheme.Font.body, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))

                Text(String(format: "$%.2f", totalSpending))
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.white)

                // "This Month" chip
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11, weight: .medium))
                    Text("This Month")
                        .font(.system(size: AppTheme.Font.caption, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.18))
                .cornerRadius(AppTheme.Radius.pill)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 148)
    }
}

#Preview {
    TotalSpendingCardView(totalSpending: 485.00)
        .padding()
        .background(Color.rsBackgroundGreen)
}
