
import SwiftUI

struct BudgetSetSuccessView: View {

    let onContinue: () -> Void   // pops entire navigation stack back to dashboard

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
                Text("Budget Set\nSuccess")
                    .font(.system(size: AppTheme.Font.title, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Budget successfully set")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
            }

            Spacer()

            // Continue CTA
            Button(action: onContinue) {
                Text("Continue")
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
    BudgetSetSuccessView(onContinue: {})
}
