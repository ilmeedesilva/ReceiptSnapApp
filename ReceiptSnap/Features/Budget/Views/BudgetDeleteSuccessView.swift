
import SwiftUI

struct BudgetDeleteSuccessView: View {

    let onBackToDashboard: () -> Void   // pops entire stack back to dashboard

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 112, height: 112)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.rsForestGreen)
            }

            // Message
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Budget Deleted\nSuccessfully")
                    .font(.system(size: AppTheme.Font.title, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Your monthly budget has been removed.")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
            }

            Spacer()

            // Back to Dashboard CTA
            Button(action: onBackToDashboard) {
                Text("Back to Dashboard")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsDeepGreen)
                    .cornerRadius(AppTheme.Radius.button)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rsCardBackground)
        .navigationBarHidden(true)
    }
}


#Preview {
    BudgetDeleteSuccessView(onBackToDashboard: {})
}
