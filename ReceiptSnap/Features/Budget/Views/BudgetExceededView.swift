
import SwiftUI

struct BudgetExceededView: View {

    let onEditBudget: () -> Void       // navigates to EditBudgetView
    let onBackToDashboard: () -> Void  // pops back to dashboard root

    var body: some View {
        ZStack {
            // Blurred background (simulates the overlay look in the Figma)
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {

                // Alert icon
                ZStack {
                    Circle()
                        .fill(Color.rsError.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.rsError)
                }

                // Message
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Budget exceeded")
                        .font(.system(size: AppTheme.Font.title, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                    Text("You have exceeded your monthly budget.\nPlease review your spending habits or\nadjust your limits.")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                        .multilineTextAlignment(.center)
                }

                // Action buttons
                VStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: onEditBudget) {
                        Text("Edit Budget")
                            .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Height.button)
                            .background(Color.rsDeepGreen)
                            .cornerRadius(AppTheme.Radius.button)
                    }

                    Button(action: onBackToDashboard) {
                        Text("Back to Dashboard")
                            .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                            .foregroundColor(.rsDeepGreen)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Height.button)
                            .background(Color.rsLightGreen)
                            .cornerRadius(AppTheme.Radius.button)
                    }
                }
            }
            .padding(AppTheme.Spacing.xl)
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.card * 2)
            .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .navigationBarHidden(true)
    }
}


#Preview {
    BudgetExceededView(
        onEditBudget: {},
        onBackToDashboard: {}
    )
}
