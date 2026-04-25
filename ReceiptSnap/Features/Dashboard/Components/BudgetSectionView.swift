
import SwiftUI


struct BudgetSectionView: View {

    let budget:          Budget?
    let onSetBudget:     () -> Void
    /// Tapping the active budget card navigates to Budget Overview.
    var onBudgetCardTap: () -> Void = {}

    var body: some View {
        if let budget {
            Button(action: onBudgetCardTap) {
                BudgetProgressCard(budget: budget)
            }
            .buttonStyle(.plain)
        } else {
            BudgetEmptyCard(onSetBudget: onSetBudget)
        }
    }
}


private struct BudgetEmptyCard: View {

    let onSetBudget: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {

            // Icon + titles row
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(Color.rsLightGreen)
                        .frame(width: 48, height: 48)
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.rsForestGreen)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Budget")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(.rsTextPrimary)
                    Text("Set your monthly budget")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
            }

            // CTA button
            Button(action: onSetBudget) {
                Text("Set Budget")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsDeepGreen)
                    .cornerRadius(AppTheme.Radius.button)
            }
        }
        .rsCardStyle()
    }
}


private struct BudgetProgressCard: View {

    let budget: Budget

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // Header: title + ACTIVE badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Budget")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(.rsTextPrimary)
                    Text("Current period: \(budget.period)")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Text("ACTIVE")
                    .font(.system(size: AppTheme.Font.caption, weight: .bold))
                    .foregroundColor(.rsForestGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.rsLightGreen)
                    .cornerRadius(AppTheme.Radius.pill)
            }

            // Spending vs limit + status
            HStack(alignment: .firstTextBaseline) {
                // "$320 / $500"
                (
                    Text("$\(Int(budget.currentSpending))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.rsDeepGreen)
                    +
                    Text(" / $\(Int(budget.monthlyLimit))")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                )
                Spacer()
                // Status indicator
                HStack(spacing: 4) {
                    if !budget.isOverBudget {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.rsForestGreen)
                    }
                    Text(budget.statusText)
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(budget.isOverBudget ? .rsError : .rsForestGreen)
                        .multilineTextAlignment(.trailing)
                }
            }

            // Progress bar + labels
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.rsBorder)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(budget.isOverBudget ? Color.rsError : Color.rsForestGreen)
                            .frame(
                                width: geo.size.width * budget.percentConsumed,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.6), value: budget.percentConsumed)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(Int(budget.percentConsumed * 100))% consumed")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                    Spacer()
                    Text("$\(Int(max(budget.remaining, 0))) remaining")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
            }
        }
        .rsCardStyle()
    }
}


#Preview("No budget") {
    BudgetSectionView(budget: nil, onSetBudget: {}, onBudgetCardTap: {})
        .padding()
        .background(Color.rsBackgroundGreen)
}

#Preview("Budget active") {
    BudgetSectionView(budget: Budget.mock(), onSetBudget: {}, onBudgetCardTap: {})
        .padding()
        .background(Color.rsBackgroundGreen)
}

#Preview("Budget exceeded") {
    BudgetSectionView(
        budget: Budget(monthlyLimit: 500, currentSpending: 560, period: "April 2026"),
        onSetBudget: {},
        onBudgetCardTap: {}
    )
    .padding()
    .background(Color.rsBackgroundGreen)
}
