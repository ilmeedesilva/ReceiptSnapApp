
import SwiftUI

struct BudgetFeedbackView: View {

    let budget: Budget
    let onViewDashboard: () -> Void   // pops to dashboard root
    let onDismiss: () -> Void         // dismisses to previous screen

    // Mock insight values — replace with real data from service when available.
    private let efficiencyPercent: Double = 12.4
    private let savingsAmount: Double     = 420.0

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    Spacer().frame(height: 60)

                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.rsLightGreen)
                            .frame(width: 96, height: 96)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.rsForestGreen)
                    }

                    // Headline
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Good job managing\nyour budget!")
                            .font(.system(size: AppTheme.Font.title, weight: .bold))
                            .foregroundColor(.rsTextPrimary)
                            .multilineTextAlignment(.center)
                        Text("Keep tracking your expenses.")
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsTextSecondary)
                    }

                    // Insight cards
                    VStack(spacing: AppTheme.Spacing.sm) {
                        efficiencyCard
                        HStack(spacing: AppTheme.Spacing.sm) {
                            healthCard
                            savingsCard
                        }
                    }

                    // Action buttons
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Button(action: onViewDashboard) {
                            Text("View My Dashboard")
                                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppTheme.Height.button)
                                .background(Color.rsDeepGreen)
                                .cornerRadius(AppTheme.Radius.button)
                        }

                        Button(action: onDismiss) {
                            Text("Dismiss")
                                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                                .foregroundColor(.rsDeepGreen)
                                .frame(maxWidth: .infinity)
                                .frame(height: AppTheme.Height.button)
                                .background(Color.rsLightGreen)
                                .cornerRadius(AppTheme.Radius.button)
                        }
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
    }

    // MARK: - Insight cards

    private var efficiencyCard: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("SPENDING VS LAST MONTH")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Text("-\(String(format: "%.1f", efficiencyPercent))% Efficient")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
            }
            Spacer()
        }
        .rsCardStyle()
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("HEALTH")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.rsBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.rsForestGreen)
                        .frame(width: geo.size.width * 0.9, height: 6)
                }
            }
            .frame(height: 6)

            Text("Excellent")
                .font(.system(size: AppTheme.Font.body, weight: .bold))
                .foregroundColor(.rsTextPrimary)
        }
        .rsCardStyle()
        .frame(maxWidth: .infinity)
    }

    private var savingsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("SAVINGS")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
            Spacer()
            Text("$\(String(format: "%.2f", savingsAmount))")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .bold))
                .foregroundColor(.rsTextPrimary)
        }
        .rsCardStyle()
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    BudgetFeedbackView(
        budget: Budget.mock(),
        onViewDashboard: {},
        onDismiss: {}
    )
}
