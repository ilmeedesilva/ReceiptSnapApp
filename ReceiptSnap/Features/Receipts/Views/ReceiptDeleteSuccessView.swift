import SwiftUI

struct ReceiptDeleteSuccessView: View {

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 112, height: 112)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.rsForestGreen)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Receipt Delete\nSuccess")
                    .font(.system(size: AppTheme.Font.title, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                    .multilineTextAlignment(.center)
                Text("Receipt successfully deleted")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
            }

            Spacer()

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
        .background(Color.white)
        .navigationBarHidden(true)
    }
}

#Preview {
    ReceiptDeleteSuccessView(onContinue: {})
}
